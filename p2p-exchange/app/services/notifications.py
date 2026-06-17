import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import current_app

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self, app=None):
        self.app = app

    def send_trade_notification(self, trade, event_type, user):
        self._send_inapp(trade, event_type, user)
        if current_app.config.get('SMTP_HOST'):
            self._send_email(trade, event_type, user)

    def _send_inapp(self, trade, event_type, user):
        logger.info(f"In-app notification: trade={trade.id}, event={event_type}, user={user.id}")

    def _send_email(self, trade, event_type, user):
        smtp_host = current_app.config.get('SMTP_HOST')
        smtp_port = current_app.config.get('SMTP_PORT', 587)
        smtp_user = current_app.config.get('SMTP_USER')
        smtp_pass = current_app.config.get('SMTP_PASS')
        if not all([smtp_host, smtp_user, smtp_pass]):
            return
        subject = f"P2P Exchange: Trade #{trade.id} - {event_type}"
        body = f"Your trade #{trade.id} has been updated. Status: {trade.status}. Event: {event_type}"
        try:
            msg = MIMEMultipart()
            msg['From'] = smtp_user
            msg['To'] = smtp_user
            msg['Subject'] = subject
            msg.attach(MIMEText(body, 'plain'))
            with smtplib.SMTP(smtp_host, smtp_port) as server:
                server.starttls()
                server.login(smtp_user, smtp_pass)
                server.send_message(msg)
        except Exception as e:
            logger.error(f"Failed to send email notification: {e}")

    def notify_escrow_funded(self, trade):
        logger.info(f"Escrow funded for trade {trade.id}")

    def notify_fiat_sent(self, trade):
        logger.info(f"Fiat sent for trade {trade.id}")

    def notify_trade_completed(self, trade):
        logger.info(f"Trade {trade.id} completed")

    def notify_dispute_opened(self, trade):
        logger.info(f"Dispute opened for trade {trade.id}")
