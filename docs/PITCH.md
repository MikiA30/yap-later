# Pitch (about 2.5 minutes)

**0:00 Problem.** "Budgeting apps start by asking for your bank login. A lot of us just won't do that. And the alternative, typing every purchase into a form, nobody keeps up for more than a week."

**0:20 Idea.** "Yap Later is a budget you talk to. Everything, the speech recognition, the language model, your data, runs on this phone. Watch: I'm turning on airplane mode." (Show Control Center, airplane on, Wi-Fi off.)

**0:35 Demo 1, expense + nudge.** Press the Action Button (or hold the orange button): "Just spent fifty bucks on groceries at Walmart." The card lands in Groceries, the weekly total rolls up, the budget bar fills, and the phone says "Only $… left for Groceries this week."

**1:05 Demo 2, it asks instead of guessing.** "Grabbed a coffee." It asks "How much was it?" Hold: "Six fifty." It logs $6.50 under Coffee. "It never makes up a number. If you don't say an amount, it asks."

**1:30 Demo 3, ramble and reminders.** "Twelve on lunch, six fifty on coffee and twenty two on an Uber." Three expenses land at once; one Undo would remove all three. Then: "Remind me to pay rent tomorrow at six pm." A card shows the title and exact time; tap Save and it is in Apple Reminders. (If short on time, do only one of these, or swap in "Set my fun budget to forty a week.")

**1:50 How.** "Speech is Argmax's WhisperKit. Understanding is PrismML's Ternary Bonsai 2, the 4-billion-parameter model, running through llama.cpp on the iPhone's GPU, about a second and a half per sentence. We tested 2B and 4B on the phone: 12 out of 20 versus 20 out of 20, so we ship the 4B. With reminders added it now scores 23 out of 23. The model only proposes; plain Swift code checks every amount and date before anything is saved."

**2:15 Why it matters.** "Private by construction: there's no server to breach and no bank token to leak. And it's fast enough that logging a purchase takes less time than unlocking a banking app."

**2:25 Next.** "A nudge when you walk into the coffee shop that's eating your budget, and a more natural voice."

## Demo checklist

- Phone charged, Auto-Lock off, volume up, Do Not Disturb off.
- App opened once after the last install so the speech model is warm (first load after an install can take a minute).
- Budgets set and the week pre-logged through the app so the live grocery yap crosses the "low" line (25% of the limit, or $50 for limits over $200). Example: Groceries budget $200 with $100 already logged; the live $50 leaves exactly $50.
- Airplane mode on, Wi-Fi and Bluetooth off, Mac unplugged.
- Reminders access already granted (save one reminder before the demo so the permission prompt does not appear live).
- Backup: screen recording of the same flow made in airplane mode.
