import urllib.request
import json
import datetime

url = 'https://firestore.googleapis.com/v1/projects/golden-paw-database/databases/(default)/documents/updates'
data = {
    "fields": {
        "title": {"stringValue": "📱 Huge Mobile Ad Fixes & Layout Improvements!"},
        "message": {"stringValue": "Today we deployed several major updates to greatly improve your experience, especially for our mobile users!\n\n✨ **What's New:**\n- **Mobile Ad Timers Fixed:** We've completely rewritten the timer logic for PTC and Bonus ads. Mobile devices will no longer freeze your timers when you switch tabs!\n- **Absolute Time Tracking:** The ad timers now reliably track the absolute time you spend away, making it impossible to get stuck on a \"Paused\" screen. Just wait the required time, and your Captcha will be waiting for you!\n- **UI Cleanups:** We've removed the unnecessary sidebars on the landing page, cleaned up the spacing on the faucet page, and added helpful notices so you know exactly where your earnings are going.\n- **Haptic Feedback:** Your device will now gently vibrate the moment an ad timer finishes, so you know exactly when it's safe to claim!\n\n🚧 **What's Next:**\nWhile the timers are now much more reliable, we know there is still more work to be done on the ads. We are continuing to polish the ad experience to make it as smooth and foolproof as possible. Stay tuned for even more improvements!"},
        "timestamp": {"timestampValue": datetime.datetime.utcnow().isoformat() + "Z"}
    }
}

req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    response = urllib.request.urlopen(req)
    print("Success:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("Error:", e.read().decode('utf-8'))
