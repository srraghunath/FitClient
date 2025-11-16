const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Start seeding ...');

  // Seed Exercises
  await prisma.exercise.createMany({
    data: [
      { name: 'Squat', bodyPart: 'LOWER_BODY', description: 'A fundamental lower body exercise.' },
      { name: 'Bench Press', bodyPart: 'UPPER_BODY', description: 'A fundamental upper body exercise for chest, shoulders, and triceps.' },
      { name: 'Deadlift', bodyPart: 'FULL_BODY', description: 'A full body compound exercise.' },
      { name: 'Overhead Press', bodyPart: 'UPPER_BODY', description: 'Builds shoulder strength.' },
      { name: 'Pull Up', bodyPart: 'UPPER_BODY', description: 'Excellent for back and bicep development.' },
    ]
  });

  // Seed Food Items
  await prisma.foodItem.createMany({
    data: [
      { name: 'Chicken Breast', calories: 165, protein: 31, carbs: 0, fat: 3.6 },
      { name: 'Brown Rice', calories: 111, protein: 2.6, carbs: 23, fat: 0.9 },
      { name: 'Broccoli', calories: 55, protein: 3.7, carbs: 11, fat: 0.6 },
      { name: 'Salmon', calories: 208, protein: 20, carbs: 0, fat: 13 },
      { name: 'Avocado', calories: 160, protein: 2, carbs: 9, fat: 15 },
    ]
  });

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
