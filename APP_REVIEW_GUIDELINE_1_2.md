# App Review Guide - Guideline 1.2 (User-Generated Content)

This app now includes the required protections for user-generated chat content.

## Implemented Protections

1. Terms gate before UGC access
- Users must accept Terms of Use before entering chat.
- Terms clearly state zero tolerance for objectionable content and abusive users.

2. Objectionable content filter
- Outgoing chat messages are checked before send.
- Messages containing objectionable terms are blocked from sending.
- Displayed message text is sanitized to mask blocked terms.

3. Report mechanism
- Users can report messages from the chat UI.
- Reports are persisted in Supabase `content_reports` table.
- Reports include reason, message, conversation, reporter, and reported user.

4. Block mechanism
- Users can block abusive users from the chat UI.
- Blocking also files a moderation report automatically.
- Blocked users are removed from the current chat feed immediately.
- Composer is disabled when the other participant is blocked.

5. 24-hour moderation workflow support
- Reports are stored with an `action_deadline` set to 24 hours.
- Pending items are visible via `moderation_queue` view.

## Supabase Objects Added

- `ugc_terms_acceptance`
- `content_reports`
- `blocked_users`
- `moderation_queue` view

All new tables have RLS policies for user-scoped access.

## Screen Recording Checklist for App Store Connect

Record on a physical device and include this in App Review Notes:

1. Terms / EULA flow
- Open chat for the first time.
- Show Terms of Use alert requiring acceptance.
- Tap "I Agree" and proceed into chat.

2. Flag content flow
- Open a conversation with existing messages.
- Swipe or tap a received message.
- Select "Report" and choose a reason.
- Show success alert.

3. Block abusive user flow
- Swipe or tap a received message.
- Select "Block User" and choose a reason.
- Show success alert and immediate removal of blocked user's messages.
- Show disabled composer indicating blocked state.

## Operations Note

Moderation team must review and act on pending reports within 24 hours:
- Remove objectionable content.
- Eject abusive users.
