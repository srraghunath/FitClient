const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const morgan = require('morgan');

const prisma = new PrismaClient();
const app = express();
const PORT = 3000;
const DEFAULT_SESSION_DURATION_MINUTES = 60;

const logApi = (context, message, data = {}) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${context}] ${message} ${JSON.stringify(data)}`);
};

const UserRole = {
  CLIENT: 'CLIENT',
  TRAINER: 'TRAINER'
};

const DayOfWeek = {
    MONDAY: 'MONDAY',
    TUESDAY: 'TUESDAY',
    WEDNESDAY: 'WEDNESDAY',
    THURSDAY: 'THURSDAY',
    FRIDAY: 'FRIDAY',
    SATURDAY: 'SATURDAY',
    SUNDAY: 'SUNDAY'
};

const MealTime = {
    BREAKFAST: 'BREAKFAST',
    LUNCH: 'LUNCH',
    DINNER: 'DINNER',
    SNACK: 'SNACK'
};

app.use(morgan('combined')); 
app.use(express.json());

// --- MIDDLEWARE ---
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

const authorizeRole = (role) => {
  return (req, res, next) => {
    if (req.user.role !== role) {
      return res.status(403).json({ error: 'Forbidden: Insufficient permissions' });
    }
    next();
  };
};


// --- AUTH ROUTES ---
app.post('/api/auth/signup',
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('fullName').notEmpty(),
  body('role').isIn([UserRole.CLIENT, UserRole.TRAINER]),
  body('specialization').if(body('role').equals(UserRole.TRAINER)).notEmpty(),
  body('goals').if(body('role').equals(UserRole.CLIENT)).notEmpty(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.error('Validation errors:', errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, fullName, role, specialization, goals } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    try {
      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          fullName,
          role,
          specialization: role === UserRole.TRAINER ? specialization : null,
          goals: role === UserRole.CLIENT ? goals : null,
        },
      });
      res.status(201).json({ message: 'User created successfully', userId: user.id });
    } catch (error) {
      res.status(400).json({ error: 'Email already exists' });
    }
  }
);

app.post('/api/auth/login',
  body('email').isEmail(),
  body('password').notEmpty(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });

    if (user && await bcrypt.compare(password, user.password)) {
      const accessToken = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1d' });
      res.json({ accessToken });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  }
);

// --- TRAINER ROUTES ---
app.post('/api/trainer/clients',
  authenticateToken,
  authorizeRole(UserRole.TRAINER),
  body('clientEmail').isEmail(),
  async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
          return res.status(400).json({ errors: errors.array() });
      }

      const { clientEmail } = req.body;
      const trainerId = req.user.id;

      try {
          const client = await prisma.user.findUnique({ where: { email: clientEmail } });
          if (!client || client.role !== UserRole.CLIENT) {
              return res.status(404).json({ error: 'Client not found or user is not a client' });
          }

          const existingLink = await prisma.clientTrainer.findUnique({
              where: { clientId: client.id }
          });

          if (existingLink) {
              return res.status(409).json({ error: 'Client is already linked to a trainer.' });
          }

          const clientTrainer = await prisma.clientTrainer.create({
              data: {
                  trainerId: trainerId,
                  clientId: client.id,
              },
          });
          res.status(201).json(clientTrainer);
      } catch (error) {
          console.error(error);
          res.status(500).json({ error: 'Server error linking client' });
      }
  }
);


// --- SESSION ROUTES ---
app.post('/api/sessions',
    authenticateToken,
    authorizeRole(UserRole.TRAINER),
    body('clientId').notEmpty(),
    body('startTime').isISO8601(),
    body('endTime').optional().isISO8601(),
    body('notes').optional().isString(),
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            logApi('Sessions', 'Validation failed for create', { errors: errors.array() });
            return res.status(400).json({ errors: errors.array() });
        }

        const trainerId = req.user.id;
        const { clientId, startTime, endTime, notes } = req.body;

        try {
            const link = await prisma.clientTrainer.findFirst({
                where: { clientId, trainerId }
            });

            if (!link) {
                logApi('Sessions', 'Trainer attempted to schedule for non-linked client', { trainerId, clientId });
                return res.status(403).json({ error: 'Forbidden: You are not linked with this client.' });
            }

            const start = new Date(startTime);
            const resolvedEnd = endTime ? new Date(endTime) : new Date(start.getTime() + DEFAULT_SESSION_DURATION_MINUTES * 60000);

            if (Number.isNaN(start.getTime()) || Number.isNaN(resolvedEnd.getTime())) {
                return res.status(400).json({ error: 'Invalid start or end time provided.' });
            }

            if (resolvedEnd <= start) {
                return res.status(400).json({ error: 'End time must be after start time.' });
            }

            const session = await prisma.session.create({
                data: {
                    trainerId,
                    clientId,
                    startTime: start,
                    endTime: resolvedEnd,
                    notes: notes ?? undefined,
                },
                include: {
                    client: { select: { id: true, fullName: true, email: true } },
                    trainer: { select: { id: true, fullName: true, email: true } },
                }
            });

            logApi('Sessions', 'Session created', { sessionId: session.id, trainerId, clientId });
            return res.status(201).json(session);
        } catch (error) {
            console.error(error);
            return res.status(500).json({ error: 'Failed to create session.' });
        }
    }
);

app.get('/api/sessions/list/:userId',
    authenticateToken,
    async (req, res) => {
        const { userId } = req.params;
        const requesterId = req.user.id;

        if (userId !== requesterId) {
            logApi('Sessions', 'Unauthorized list attempt', { userId, requesterId });
            return res.status(403).json({ error: 'Forbidden: You can only view your own sessions.' });
        }

        try {
            const sessions = await prisma.session.findMany({
                where: {
                    OR: [{ trainerId: userId }, { clientId: userId }]
                },
                orderBy: { startTime: 'asc' },
                include: {
                    client: { select: { id: true, fullName: true, email: true } },
                    trainer: { select: { id: true, fullName: true, email: true } },
                }
            });

            logApi('Sessions', 'Sessions fetched', { userId, count: sessions.length });
            return res.json({ sessions });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ error: 'Failed to retrieve sessions.' });
        }
    }
);

app.put('/api/sessions/:sessionId',
    authenticateToken,
    authorizeRole(UserRole.TRAINER),
    body('startTime').optional().isISO8601(),
    body('endTime').optional().isISO8601(),
    body('notes').optional().isString(),
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            logApi('Sessions', 'Validation failed for update', { errors: errors.array() });
            return res.status(400).json({ errors: errors.array() });
        }

        const { sessionId } = req.params;
        const trainerId = req.user.id;
        const { startTime, endTime, notes } = req.body;

        if (!startTime && !endTime && typeof notes === 'undefined') {
            return res.status(400).json({ error: 'Provide at least one field to update.' });
        }

        try {
            const existing = await prisma.session.findUnique({
                where: { id: sessionId }
            });

            if (!existing) {
                return res.status(404).json({ error: 'Session not found.' });
            }

            if (existing.trainerId !== trainerId) {
                logApi('Sessions', 'Trainer attempted to modify session not owned', { sessionId, trainerId });
                return res.status(403).json({ error: 'Forbidden: You do not own this session.' });
            }

            const updateData = {};
            let newStart = startTime ? new Date(startTime) : null;
            let newEnd = endTime ? new Date(endTime) : null;

            if (newStart && Number.isNaN(newStart.getTime())) {
                return res.status(400).json({ error: 'Invalid start time provided.' });
            }

            if (newEnd && Number.isNaN(newEnd.getTime())) {
                return res.status(400).json({ error: 'Invalid end time provided.' });
            }

            if (newStart) {
                updateData.startTime = newStart;
            }

            if (newEnd) {
                updateData.endTime = newEnd;
            }

            if (newStart && !newEnd) {
                newEnd = new Date(newStart.getTime() + DEFAULT_SESSION_DURATION_MINUTES * 60000);
                updateData.endTime = newEnd;
            }

            if (!newStart && newEnd && !existing.startTime) {
                return res.status(400).json({ error: 'Cannot set end time without a start time.' });
            }

            const effectiveStart = newStart ?? existing.startTime;
            const effectiveEnd = newEnd ?? existing.endTime;

            if (effectiveEnd && effectiveStart && effectiveEnd <= effectiveStart) {
                return res.status(400).json({ error: 'End time must be after start time.' });
            }

            if (typeof notes !== 'undefined') {
                updateData.notes = notes;
            }

            const updated = await prisma.session.update({
                where: { id: sessionId },
                data: updateData,
                include: {
                    client: { select: { id: true, fullName: true, email: true } },
                    trainer: { select: { id: true, fullName: true, email: true } },
                }
            });

            logApi('Sessions', 'Session updated', { sessionId, trainerId });
            return res.json(updated);
        } catch (error) {
            console.error(error);
            return res.status(500).json({ error: 'Failed to update session.' });
        }
    }
);

app.delete('/api/sessions/:sessionId',
    authenticateToken,
    authorizeRole(UserRole.TRAINER),
    async (req, res) => {
        const { sessionId } = req.params;
        const trainerId = req.user.id;

        try {
            const existing = await prisma.session.findUnique({ where: { id: sessionId } });

            if (!existing) {
                return res.status(404).json({ error: 'Session not found.' });
            }

            if (existing.trainerId !== trainerId) {
                logApi('Sessions', 'Trainer attempted to delete session not owned', { sessionId, trainerId });
                return res.status(403).json({ error: 'Forbidden: You do not own this session.' });
            }

            await prisma.session.delete({ where: { id: sessionId } });
            logApi('Sessions', 'Session deleted', { sessionId, trainerId });
            return res.status(204).send();
        } catch (error) {
            console.error(error);
            return res.status(500).json({ error: 'Failed to delete session.' });
        }
    }
);


// --- SCHEDULE ROUTES ---
app.post('/api/schedule/template/:clientId/:dayOfWeek',
  authenticateToken,
  authorizeRole(UserRole.TRAINER),
  async (req, res) => {
    const { clientId, dayOfWeek } = req.params;
    const { sleepTargetHours, waterTargetLiters, cardioPlanText } = req.body;

    if (!Object.values(DayOfWeek).includes(dayOfWeek.toUpperCase())) {
        return res.status(400).json({ error: 'Invalid day of the week.' });
    }

    try {
        // Verify client is linked to this trainer
        const link = await prisma.clientTrainer.findFirst({
            where: { clientId: clientId, trainerId: req.user.id }
        });
        if (!link) {
            return res.status(403).json({ error: "Forbidden: You are not this client's trainer." });
        }

        const template = await prisma.weeklyScheduleTemplate.upsert({
            where: { clientId_dayOfWeek: { clientId, dayOfWeek: dayOfWeek.toUpperCase() } },
            update: { sleepTargetHours, waterTargetLiters, cardioPlanText },
            create: { clientId, dayOfWeek: dayOfWeek.toUpperCase(), sleepTargetHours, waterTargetLiters, cardioPlanText },
        });
        res.status(201).json(template);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to create or update schedule template.' });
    }
  }
);

app.post('/api/schedule/workout/:templateId',
    authenticateToken,
    authorizeRole(UserRole.TRAINER),
    body('exerciseId').notEmpty(),
    body('sets').isInt({ min: 1 }),
    body('reps').notEmpty(),
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { templateId } = req.params;
        const { exerciseId, sets, reps } = req.body;

        try {
            // Ensure the template belongs to a client of the trainer
            const template = await prisma.weeklyScheduleTemplate.findUnique({
                where: { id: templateId },
                include: { client: { include: { trainerLink: true } } }
            });

            if (!template || template.client.trainerLink?.trainerId !== req.user.id) {
                return res.status(403).json({ error: 'Forbidden: You cannot modify this schedule.' });
            }

            const scheduledExercise = await prisma.scheduledTemplateExercise.create({
                data: { templateId, exerciseId, sets, reps },
            });
            res.status(201).json(scheduledExercise);
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: 'Failed to add exercise to schedule.' });
        }
    }
);

app.post('/api/schedule/meal/:templateId',
    authenticateToken,
    authorizeRole(UserRole.TRAINER),
    body('foodItemId').notEmpty(),
    body('mealTime').isIn(Object.values(MealTime)),
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { templateId } = req.params;
        const { foodItemId, mealTime, quantityText } = req.body;

        try {
            // Ensure the template belongs to a client of the trainer
            const template = await prisma.weeklyScheduleTemplate.findUnique({
                where: { id: templateId },
                include: { client: { include: { trainerLink: true } } }
            });

            if (!template || template.client.trainerLink?.trainerId !== req.user.id) {
                return res.status(403).json({ error: 'Forbidden: You cannot modify this schedule.' });
            }

            const scheduledMeal = await prisma.scheduledTemplateMealItem.create({
                data: { templateId, foodItemId, mealTime, quantityText },
            });
            res.status(201).json(scheduledMeal);
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: 'Failed to add meal to schedule.' });
        }
    }
);


app.get('/api/schedule/today', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const today = new Date();
    const dayOfWeek = today.toLocaleDateString('en-US', { weekday: 'long' }).toUpperCase();

    try {
        const template = await prisma.weeklyScheduleTemplate.findFirst({
            where: {
                clientId: userId,
                dayOfWeek: dayOfWeek,
            },
            include: {
                scheduledExercises: { include: { exercise: true } },
                scheduledMealItems: { include: { foodItem: true } },
            },
        });

        if (!template) {
            return res.status(404).json({ message: "No schedule found for today." });
        }

        res.json(template);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to retrieve today\'s schedule.' });
    }
});


// --- ACTIVITY ROUTES ---
app.put('/api/activity/log',
  authenticateToken,
  body('date').isISO8601().toDate(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const clientId = req.user.id;
    const { date, ...updates } = req.body;

    // Normalize date to remove time part for consistent daily logging
    const logDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    try {
        const log = await prisma.clientActivityLog.upsert({
            where: { clientId_date: { clientId, date: logDate } },
            update: { ...updates },
            create: { clientId, date: logDate, ...updates },
        });
        res.json(log);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to log activity.' });
    }
  }
);

app.get('/api/activity/summary/:clientId', authenticateToken, async (req, res) => {
    const { clientId } = req.params;
    const requesterId = req.user.id;
    const requesterRole = req.user.role;

    try {
        if (requesterRole === UserRole.CLIENT && requesterId !== clientId) {
            return res.status(403).json({ error: "Forbidden: You can only view your own activity." });
        }

        if (requesterRole === UserRole.TRAINER) {
            const link = await prisma.clientTrainer.findFirst({
                where: { clientId: clientId, trainerId: requesterId }
            });
            if (!link) {
                return res.status(403).json({ error: "Forbidden: You are not this client's trainer." });
            }
        }

        const summary = await prisma.clientActivityLog.findMany({
            where: { clientId: clientId },
            orderBy: { date: 'desc' },
        });

        res.json(summary);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to retrieve activity summary.' });
    }
});

// Dev route to get exercises for testing
app.get('/dev/exercises', async (req, res) => {
    const exercises = await prisma.exercise.findMany();
    res.json(exercises);
});


app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
