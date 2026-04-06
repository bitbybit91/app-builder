"""
Notification Service
=====================
Multi-channel notification system.

Supported channels:
  - In-app (WebSocket / SSE)
  - Email (SMTP)
  - Nostr protocol
"""

import json
import logging
import smtplib
from email.mime.text import MIMEText

import requests

logger = logging.getLogger(__name__)


class NotificationService:
    """Send notifications through multiple channels."""

    def __init__(self, smtp_config=None, nostr_config=None):
        """
        Initialize notification service.

        Args:
            smtp_config: Dict with host, port, user, password, from_addr.
            nostr_config: Dict with relay_url, private_key.
        """
        self.smtp_config = smtp_config or {}
        self.nostr_config = nostr_config or {}
        # In-app notification queue (per-user)
        self._in_app_queue = {}

    def notify(self, user_id, title, message, channels=None):
        """
        Send a notification to a user through specified channels.

        Args:
            user_id: Target user ID.
            title: Notification title.
            message: Notification body.
            channels: List of channels ('in_app', 'email', 'nostr').
                      Defaults to ['in_app'].
        """
        channels = channels or ['in_app']

        for channel in channels:
            try:
                if channel == 'in_app':
                    self._send_in_app(user_id, title, message)
                elif channel == 'email':
                    self._send_email(user_id, title, message)
                elif channel == 'nostr':
                    self._send_nostr(title, message)
                else:
                    logger.warning('Unknown notification channel: %s', channel)
            except Exception as exc:
                logger.error('Failed to send %s notification to %s: %s',
                             channel, user_id[:8], exc)

    def _send_in_app(self, user_id, title, message):
        """Queue an in-app notification."""
        if user_id not in self._in_app_queue:
            self._in_app_queue[user_id] = []

        self._in_app_queue[user_id].append({
            'title': title,
            'message': message,
        })

        logger.debug('In-app notification queued for user %s', user_id[:8])

    def get_in_app_notifications(self, user_id):
        """
        Get and clear pending in-app notifications for a user.

        Args:
            user_id: User ID.

        Returns:
            list: List of notification dicts.
        """
        notifications = self._in_app_queue.pop(user_id, [])
        return notifications

    def _send_email(self, user_id, title, message):
        """Send an email notification (if SMTP configured)."""
        if not self.smtp_config.get('host'):
            logger.debug('SMTP not configured, skipping email notification')
            return

        # Note: In a no-KYC system, email is optional and user-provided
        msg = MIMEText(message)
        msg['Subject'] = title
        msg['From'] = self.smtp_config.get('from_addr', 'noreply@example.onion')
        msg['To'] = user_id  # In practice, look up user's optional email

        try:
            with smtplib.SMTP(
                self.smtp_config['host'],
                self.smtp_config.get('port', 587),
            ) as server:
                if self.smtp_config.get('user'):
                    server.starttls()
                    server.login(
                        self.smtp_config['user'],
                        self.smtp_config['password'],
                    )
                server.send_message(msg)
                logger.info('Email notification sent for %s', title)
        except Exception as exc:
            logger.error('Email send failed: %s', exc)

    def _send_nostr(self, title, message):
        """Publish a trade event to Nostr relay (if configured)."""
        if not self.nostr_config.get('relay_url'):
            logger.debug('Nostr not configured, skipping')
            return

        # Simplified Nostr event publishing
        event = {
            'kind': 1,  # Text note
            'content': f'{title}: {message}',
            'tags': [['t', 'p2p-exchange']],
        }

        try:
            relay_url = self.nostr_config['relay_url']
            # In production, sign the event with the Nostr private key
            requests.post(
                relay_url,
                json=['EVENT', event],
                timeout=10,
            )
            logger.info('Nostr event published: %s', title)
        except Exception as exc:
            logger.error('Nostr publish failed: %s', exc)
