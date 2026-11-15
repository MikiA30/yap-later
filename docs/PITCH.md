# Video script (2:00 maximum)

Format: the presenter talks to camera; every few seconds the picture cuts to a screen recording while the voice continues, then returns. About 265 spoken words plus the app's own audio in the clips.

| Time | Picture | Words |
|---|---|---|
| 0:00 | Camera | "Budgeting apps like Rocket Money ask for two things up front: your bank login, and your data in their cloud. For a lot of people, especially anyone who doesn't trust AI with their information, that's where it ends." |
| 0:13 | Camera, then Clip 1 (airplane mode) | "This is Yap Later. Same idea, rebuilt so nothing leaves the device. No bank login, no account, and, watch, no internet." |
| 0:22 | Clip 2 (groceries yap; keep the clip's own sound) | After the nudge speaks: "You just say what you spent. It files it, updates your budget, and warns you when you're running low." |
| 0:37 | Clip 3 (coffee, it asks back) | "Leave something out and it asks. It never makes up a number." |
| 0:47 | Clip 4 (three at once, then a reminder) | "Say three things at once and it logs three. Ask for a reminder and it's in your Reminders." |
| 0:57 | Camera | "Under the hood, Argmax WhisperKit turns your voice into text, and PrismML's Bonsai 2, four billion parameters squeezed into 1.2 gigabytes, understands it in just over a second on the phone's own chip. We tested two sizes and shipped the smaller one that passed: 23 out of 23 test sentences. And the model only suggests. Plain code checks every amount before anything is saved." |
| 1:19 | Clip 5 (Mac, Wi-Fi off, sync) | "It runs natively on a Mac with Wi-Fi off, and the two sync over Bluetooth. Still no internet." |
| 1:27 | Clip 6 (interface montage) | "We also refused to ship something that looks like every AI demo. Every animation means something: the total spins when money moves, the budget steps forward and fills, and the charts are drawn from your own entries." |
| 1:41 | Camera | "So when do you need this? On a plane. Abroad with no data. In a store basement. Or any time you'd rather your money stayed your business. Yap Later: AI you can trust, because it never leaves your hands." |

## Clips to record

Record in this order on the iPhone; the first two depend on the demo week's numbers. Rehearse as much as you like, then run `scripts/demo_week.sh iphone replace` to reset before the real take.

| Clip | Do this | The viewer should see | Length |
|---|---|---|---|
| 1 | Open Control Center, turn on airplane mode, close it, open Yap Later | Airplane icon on, Wi-Fi off, bubbles rising, "Hello" | 5 s |
| 2 | Hold the orange button: "Just spent fifty bucks on groceries at Walmart" | Words appear, Groceries card grows and its bar fills, banner and voice: "Only $50 left for Groceries this week" | 12 s |
| 3 | Hold: "Grabbed a coffee". Wait for "How much was it?". Hold: "Six fifty" | The question on screen and spoken, then $6.50 saved under Coffee and a second nudge ($3.25 left) | 10 s |
| 4 | Hold: "Twelve on lunch, fifteen at the pharmacy and twenty on a shirt at Target". Then hold: "Remind me to pay rent tomorrow at six pm" and tap Save to Reminders | "Saved 3 expenses"; then the reminder card with the exact time, and "Coming up" | 12 s |
| 5 | On the Mac: turn Wi-Fi off in the menu bar, hold the button and say "Spent nine dollars on lunch". Then tap the avatar, Sync now, and do the same on the iPhone | The same app on the Mac, the entry saved, then the phone's entries arriving | 8 s |
| 6 | Swipe the big total so it spins; tap the chart button, let the columns and ring grow in, drag the ring; go back; tap the avatar and show the profile page | The 3D total spinning, charts animating, the ring tilting, the profile page | 12 s |

Notes:

- Only show what worked when you recorded it. If Sync or the Mac microphone misbehaves, cut that half of Clip 5 and its sentence.
- The week on screen is the demo week. Do not call it your own spending; "here's a week of spending" is accurate.
- iPhone screen recording: long-press the record button in Control Center and turn the microphone on so your voice is in the clip. Try a five-second test first; if recording with the microphone on stops the app from hearing you, film the phone over your shoulder instead.
- Figures used above and where they come from: 23 of 23 and about 1.3 s per sentence on the iPhone 17 Pro (`eval/results/`), 2B at 12 of 20, model file 1.2 GB.

## Demo checklist

- Phone charged, Auto-Lock off, volume up, Do Not Disturb off.
- App opened once after the last install so the speech model is warm (first load after an install can take a minute).
- Demo week loaded (`scripts/demo_week.sh iphone replace`, already done on the iPhone and the Mac at 09:38): Groceries stands at $100 of $200, so the live $50 grocery yap leaves exactly $50 and raises the nudge; Coffee stands at $15.25 of $25, so the live $6.50 coffee leaves $3.25 and raises a second one. If asked, call it what it is: a demo week. `scripts/demo_week.sh iphone restore` puts your own earlier entries back.
- Airplane mode on, Wi-Fi and Bluetooth off, Mac unplugged.
- Mac: run `scripts/setup_mac.sh` beforehand, open the app once and allow the microphone, then turn Wi-Fi off before recording the Mac segment.
- Video is at most 2:00; submit it with the GitHub link before noon.
- Before recording, check the three things that have not been seen working yet: the Mac microphone (hold the button in the Mac window and allow the prompt), the Argmax voice (listen to one question on the Mac; it is off on the iPhone until checked there), and Sync (tap Sync on the Mac, then on the iPhone, and allow Bluetooth on both). Only show or mention in the video what worked in that check. If Sync works, it fits in the Mac segment: log an expense on the phone, tap Sync on both, and it appears on the Mac.
- Reminders access already granted (save one reminder before the demo so the permission prompt does not appear live).
- Backup: screen recording of the same flow made in airplane mode.
