# Database Schema

## Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## Players Table
```sql
CREATE TABLE players (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date_of_birth DATE,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    role VARCHAR(50),
    batting_style VARCHAR(50),
    bowling_style VARCHAR(100),
    jersey_number INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## Matches Table
```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY,
    team1_id UUID REFERENCES teams(id),
    team2_id UUID REFERENCES teams(id),
    date DATE NOT NULL,
    type VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL,
    venue VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## Tournaments Table
```sql
CREATE TABLE tournaments (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    organizer_id UUID REFERENCES users(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    format VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL,
    max_teams INTEGER,
    location VARCHAR(255),
    prize_pool VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## Media Table
```sql
CREATE TABLE media (
    id UUID PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    match_id UUID REFERENCES matches(id),
    player_id UUID REFERENCES players(id),
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Stats Table
```sql
CREATE TABLE stats (
    id UUID PRIMARY KEY,
    player_id UUID REFERENCES players(id),
    match_id UUID REFERENCES matches(id),
    batting_runs INTEGER DEFAULT 0,
    batting_balls INTEGER DEFAULT 0,
    batting_fours INTEGER DEFAULT 0,
    batting_sixes INTEGER DEFAULT 0,
    bowling_overs DECIMAL(5,1) DEFAULT 0,
    bowling_runs INTEGER DEFAULT 0,
    bowling_wickets INTEGER DEFAULT 0,
    fielding_catches INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

