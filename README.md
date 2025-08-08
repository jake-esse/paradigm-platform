# Paradigm Platform

A platform where users own their data and earn equity in the apps they use.

## 🚀 Features

- **Data Ownership**: Users maintain complete control over their data
- **Permission System**: Granular permissions with time-based expiration
- **Equity Distribution**: Users earn shares in apps they use (coming soon)
- **Developer-Friendly**: Simple SDK for building apps on the platform

## 🛠️ Tech Stack

- **Backend**: Supabase (PostgreSQL, Edge Functions)
- **Security**: Row Level Security (RLS) policies
- **APIs**: RESTful Edge Functions
- **Coming Soon**: Blockchain integration for equity distribution

## 🏃‍♂️ Getting Started

### Prerequisites

- Node.js 18+
- Docker Desktop
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/paradigm-platform.git
cd paradigm-platform

2. Install Supabase CLI:

bashnpm install -g supabase

3. Start Supabase:

bashnpx supabase start

4. Apply migrations:

bashnpx supabase migration up

5. Start Edge Functions:

bashnpx supabase functions serve

6. Get your anon key:

bashnpx supabase status
# Copy the anon key

7. Update test-system.html with your anon key and open in browser

**### 📁 Project Structure**
paradigm-platform/
├── supabase/
│   ├── migrations/      # Database schema
│   └── functions/       # Edge Functions (APIs)
├── extensions/          # Platform extensions
├── sdk/                 # Developer SDK (coming soon)
└── test-system.html     # Test dashboard
🔐 Permission System
The core permission system allows:

Apps to request access to specific data types
Users to grant/revoke permissions
Time-based permission expiration
Complete audit trail

Available Edge Functions

request-permission - Apps request data access
grant-permission - Users approve requests
check-permission - Verify active permissions
revoke-permission - Remove app access

🤝 Contributing
This is a private project in active development.
📄 License
Proprietary - All Rights Reserved
🙏 Acknowledgments
Built with Supabase, PostgreSQL, and Claude Code assistance.

## 📝 **Add and Commit the README**

```bash
# Add the README
git add README.md

# Commit it
git commit -m "Add README with setup instructions"

# Push to GitHub
git push
🎯 Future Commits
For future changes, the process is simpler:
bash# See what changed
git status

# Add changes
git add .

# Commit with message
git commit -m "Your commit message here"

# Push to GitHub
git push
