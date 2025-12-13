# Module Structure

## Recommended Folder Structure

```
src/
├── app/
│   ├── (auth)/              # Authentication routes
│   ├── (dashboard)/         # Main dashboard (current)
│   ├── (player)/            # Player App module
│   ├── (coach)/             # Coach App module
│   ├── (tournament)/        # Tournament App module
│   ├── (academy)/           # Academy App module
│   └── (admin)/             # Admin Panel module
│
├── modules/
│   ├── auth/                # Authentication service
│   ├── player/               # Player App logic
│   ├── coach/                # Coach App logic
│   ├── tournament/           # Tournament logic
│   ├── academy/              # Academy logic
│   ├── match-center/         # Match Center logic
│   ├── live-streaming/       # Streaming logic
│   ├── ai-engine/            # AI processing
│   ├── payments/             # Payment processing
│   └── notifications/       # Notification service
│
├── lib/
│   ├── db/                   # Database clients
│   │   ├── user.ts
│   │   ├── player.ts
│   │   ├── match.ts
│   │   ├── tournament.ts
│   │   ├── media.ts
│   │   └── stats.ts
│   ├── api/                  # API clients
│   └── services/             # Business logic services
│
├── components/
│   ├── player/               # Player App components
│   ├── coach/                # Coach App components
│   ├── tournament/           # Tournament components
│   ├── academy/              # Academy components
│   ├── admin/               # Admin components
│   └── shared/              # Shared components
│
└── types/
    ├── auth.ts
    ├── player.ts
    ├── match.ts
    ├── tournament.ts
    └── api.ts
```

