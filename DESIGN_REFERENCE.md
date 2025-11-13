# Client Dashboard Visual Reference

## Layout Hierarchy (Top to Bottom)

```
┌─────────────────────────────────────┐
│ Status Bar (62pt)                   │ → Time, Signal, Battery
├─────────────────────────────────────┤
│ Navbar (46pt)                       │ → "Wed, 29 Oct 2025" | 📅
├─────────────────────────────────────┤
│ [ScrollView Start]                  │
│                                     │
│ Activity Summary (12pt margin)      │
│ ┌──────────────┬──────────────────┐│
│ │ Total Active │ Consecutive      ││
│ │ Days         │ Active Days      ││
│ │ 12 Days ✨   │ 7 Days ✨        ││
│ │ (158×134)    │ (158×134)        ││
│ └──────────────┴──────────────────┘│
│                                     │
│ Day Tracker (24pt margin)           │
│ ┌─────────────────────────────────┐│
│ │ 💪 Workout          Full body  ✓││
│ └─────────────────────────────────┘│
│ ┌─────────────────────────────────┐│
│ │ 🏃 Cardio      Running, 30 min   ││
│ └─────────────────────────────────┘│
│ ┌─────────────────────────────────┐│
│ │ 💧 Water Intake    8 litres      ││
│ └─────────────────────────────────┘│
│ ┌─────────────────────────────────┐│
│ │ 🌿 Diet Plan       Balanced   ✓  ││
│ └─────────────────────────────────┘│
│ ┌─────────────────────────────────┐│
│ │ 🌙 Sleep Cycle     8 hours    ✓  ││
│ └─────────────────────────────────┘│
│                                     │
│ Scheduled Workouts (24pt margin)    │
│ ┌──────────────────────────────────┐│
│ │ 📸 Push-ups    3 sets of 10 reps ││
│ └──────────────────────────────────┘│
│ ┌──────────────────────────────────┐│
│ │ 📸 Bench Press 3 sets of 12 reps ││
│ └──────────────────────────────────┘│
│ ┌──────────────────────────────────┐│
│ │ 📸 Pull-ups    3 sets of 10 reps ││
│ └──────────────────────────────────┘│
│                                     │
│ [Bottom Padding 50pt]               │
└─────────────────────────────────────┘
```

## Color Palette

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Black** | #000000 | (0, 0, 0) | Main background |
| **Dark Gray** | #000101 | (0, 1, 1) | Navbar, status bar |
| **Card Gray** | #303131 | (48, 49, 49) | Card backgrounds |
| **Light Gray** | #D7CCC8 | (215, 204, 200) | Secondary text |
| **White** | #F5F5F5 | (245, 245, 245) | Primary text |
| **Lime Green** | #AEFE14 | (174, 254, 20) | Accent, checkmarks |

## Typography

| Element | Font | Weight | Size | Color |
|---------|------|--------|------|-------|
| **Status Bar Time** | SFProDisplay | Semibold | 17pt | #FFFFFF |
| **Navbar Date** | Inter | Medium | 16pt | #F5F5F5 |
| **Section Headers** | SFProDisplay | Medium | 16pt | #F5F5F5 |
| **Card Titles** | SFProDisplay | Medium | 16pt | #F5F5F5 |
| **Card Values** | SFProDisplay | Bold | 24pt | #AEFE14 |
| **Subtitles** | SFProDisplay | Regular | 14pt | #D7CCC8 |

## Spacing Guidelines

- **Margins**: 16pt left/right throughout
- **Section Gaps**: 24pt between sections
- **Card Spacing**: 8pt padding inside cards
- **Corner Radius**: 24pt for cards, 8pt for images
- **Icon Size**: 48pt in day tracker, 56pt in workouts
- **Navbar Height**: 46pt
- **Status Bar Height**: 62pt

## Component Dimensions

### Activity Summary Cards
- Width: 158pt each
- Height: 134pt
- Corner Radius: 8pt (implied from design)
- Gap Between Cards: 45pt

### Day Tracker Item
- Height: 80pt (row height)
- Icon Container: 48×48pt
- Checkbox: 24×24pt
- Internal Padding: 16pt from icon to text

### Scheduled Workout Item
- Height: 80pt (row height)
- Image: 56×56pt with 8pt corner radius
- Left Padding: 16pt from image to text
- Layout: Horizontal (image + text column)

## Interactive Elements

✅ **Checkboxes**:
- Filled state: Lime green (#AEFE14) background with white checkmark
- Empty state: Transparent with 2pt gray border (#49454F)
- Size: 24×24pt
- Animation: Color transition on tap (when implemented)

📅 **Calendar Button**:
- Size: 24×24pt
- Color: #F5F5F5
- System Icon: "calendar"
- Position: Navbar trailing (16pt from right)

## Data Structure (activityData.json)

```javascript
[
  // Day Tracker Items
  {
    "id": "tracker_workout",
    "type": "dayTracker",
    "title": "Workout",
    "subtitle": "Full body",
    "icon": "dumbbell.2",          // SF Symbol name
    "isCompleted": true,            // Boolean for checkbox
    "date": "2025-10-29"
  },
  
  // Activity Summary
  {
    "id": "summary_total",
    "type": "activitySummary",
    "title": "Total Active Days",
    "value": "12 Days"              // Displayed directly
  },
  
  // Scheduled Workouts
  {
    "id": "workout_pushups",
    "type": "scheduledWorkout",
    "title": "Push-ups",
    "description": "3 sets of 10 reps",
    "image": "https://via.placeholder.com/56x56?text=Pushups"
  }
]
```

## Implementation Notes

- **ScrollView**: Contains entire content for scrollability
- **Table Views**: Two separate tables (DayTracker, ScheduledWorkouts)
- **Cell Height**: Fixed 80pt with 8pt padding = 96pt visual
- **Content Insets**: All margins handled via constraints
- **Auto Layout**: All components use NSLayoutConstraint
- **Dynamic Date**: Updates on viewDidLoad using DateFormatter
- **JSON Loading**: Decoded into ActivityItem struct with Codable
