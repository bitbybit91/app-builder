/**
 * Capital Monero — Frontend JavaScript
 * capitalmonero.com
 */

document.addEventListener('DOMContentLoaded', function () {
    // Auto-hide flash alerts after 5 seconds
    var alerts = document.querySelectorAll('.alert');
    alerts.forEach(function (alert) {
        setTimeout(function () {
            alert.style.transition = 'opacity 0.5s ease';
            alert.style.opacity = '0';
            setTimeout(function () {
                alert.remove();
            }, 500);
        }, 5000);
    });

    // Scroll message list to bottom
    var messageList = document.querySelector('.message-list');
    if (messageList) {
        messageList.scrollTop = messageList.scrollHeight;
    }
});
