# API Structure Documentation

## Base URL
```
https://api.cricplay.com/v1
```

## Authentication
All API requests require JWT token in header:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## API Endpoints

### Authentication APIs
```
POST   /auth/login              - Email/Password login
POST   /auth/google              - Google OAuth login
POST   /auth/apple               - Apple OAuth login
POST   /auth/refresh             - Refresh JWT token
POST   /auth/logout              - Logout user
```

### Player App APIs
```
GET    /player/profile           - Get player profile
PUT    /player/profile           - Update player profile
GET    /player/stats             - Get player statistics
GET    /player/scorecards        - Get player scorecards
GET    /player/leaderboard       - Get leaderboard data
GET    /player/matches           - Get player matches
```

### Coach App APIs
```
GET    /coach/players            - Get team players
GET    /coach/team               - Get team details
GET    /coach/analysis           - Get match analysis
GET    /coach/stats              - Get team statistics
POST   /coach/assignments        - Create training assignments
```

### Tournament APIs
```
GET    /tournament/list          - Get tournaments
GET    /tournament/:id           - Get tournament details
GET    /tournament/:id/players   - Get tournament players
GET    /tournament/:id/fixtures  - Get tournament fixtures
GET    /tournament/:id/standings - Get tournament standings
```

### Match Center APIs
```
GET    /match/live               - Get live matches
GET    /match/:id                - Get match details
GET    /match/:id/timeline       - Get match timeline
GET    /match/:id/commentary     - Get live commentary
POST   /match/:id/events         - Post match events (Admin)
```

### Academy APIs
```
GET    /academy/training         - Get training programs
GET    /academy/attendance       - Get attendance records
GET    /academy/health           - Get health metrics
GET    /academy/videos           - Get training videos
POST   /academy/attendance       - Mark attendance
```

### Admin APIs
```
GET    /admin/users              - Get all users
POST   /admin/users              - Create user
PUT    /admin/users/:id          - Update user
DELETE /admin/users/:id         - Delete user
GET    /admin/matches            - Get all matches
POST   /admin/matches            - Create match
PUT    /admin/matches/:id        - Update match
POST   /admin/tournaments        - Create tournament
GET    /admin/analytics          - Get platform analytics
```

### AI Engine APIs
```
POST   /ai/analyze-video         - Analyze video stream
GET    /ai/highlights            - Get AI-generated highlights
GET    /ai/predictions           - Get match predictions
GET    /ai/player-analysis       - Get player AI analysis
```

### Payments APIs
```
POST   /payments/create          - Create payment
POST   /payments/verify          - Verify payment
GET    /payments/history         - Get payment history
POST   /payments/subscribe       - Create subscription
```

### Notifications APIs
```
GET    /notifications            - Get user notifications
PUT    /notifications/:id/read   - Mark as read
PUT    /notifications/preferences - Update preferences
```

### Media APIs
```
GET    /media/stream/:id         - Get video stream
GET    /media/highlights/:id     - Get match highlights
POST   /media/upload             - Upload media (Admin)
```

---

## WebSocket Events

### Match Events
```
match:score-update      - Real-time score updates
match:event             - Match events (wicket, boundary)
match:timeline          - Timeline updates
match:commentary        - Live commentary
```

### Notification Events
```
notification:new        - New notification
notification:read       - Notification read status
```

### Live Stream Events
```
stream:start            - Stream started
stream:stop             - Stream stopped
stream:quality-change   - Quality change
```

