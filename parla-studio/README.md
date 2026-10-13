# Parla Studio

Live: https://parla-studio.netlify.app/

Managed by Parla. Single-page enquiry form mirroring samasta-travel/contact.html,
plus a "Select artist" dropdown (answer key `artist`).

Deploy with `SUPABASE_URL=… FORM_KEY=… HCAPTCHA_SITE_KEY=… bash parla-studio/deploy.sh`.
The repo keeps the `__TOKENS__`; the values are the prod `website-enquiry` endpoint, the
`website_form_id` of the studio manager's Parla account, and the parla-studio hCaptcha
site key (all three are visible in the live page source). The script refuses to deploy without them.
