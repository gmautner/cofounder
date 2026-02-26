# SMTP Gateway

An SMTP gateway is needed if the app sends e-mails (reminders, authentication links, etc.).

## Recommended methods

### Gmail SMTP — good for prototyping, low volume

#### 1. Generate an App Password

1. Go to <https://myaccount.google.com/security>
2. **Segurança e Login** → **Verificação em duas etapas** → ensure it is enabled
3. Type **"app passwords"** in the search field
4. Fill **Nome do app:** `SMTP`
5. Copy the 16-character generated password back to Claude

#### 2. Configure the web app

| Setting | Value |
|---------|-------|
| SMTP Server | `smtp.gmail.com` |
| Port | `587` (TLS/STARTTLS) |
| Username | Your full Gmail address |
| Password | The App Password generated above |

### Locaweb SMTP — good for production use

Sign up at <https://www.locaweb.com.br/smtp-locaweb/>. If you already have the SMTP service, go to **Central do Cliente** to retrieve your credentials.
