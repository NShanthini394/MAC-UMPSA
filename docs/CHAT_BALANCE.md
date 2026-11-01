# Discussion and solo tuning — v0.20

Chat bubbles now use PanelContainer and VBoxContainer minimum sizes derived from
the actual shaped text, with separate name and message rows. A fixed discussion
scroll area prevents long messages from covering the input box. Own messages
align right and other messages left. Names and typed messages are never translated.

Bots open with at most three speakers. A human message schedules one respondent
after a 3.5–6 second thinking pause. All replies are separated by 4.5–6.5 seconds;
each individual bot waits at least fourteen seconds between messages and sends
at most two per discussion. Pending answers are replaced by newer questions.

Solo opponents have a 45-second initial attack grace period, a forty-second
individual bot attack cooldown and a twenty-second shared interval. Solo Nenek
bots only pursue visible Villagers within 240 map units and a clear line of sight.
Villager bots wait for the human's vote until the final three seconds, consider
public nominations more often, and still prioritize evidence they witnessed.
Friends and Quick Match retain their existing attack settings. None of these
changes forces a winning side or guarantees a 50/50 outcome. Win-rate tuning
still requires repeated human playtests across all maps.

The generated render-server folder must be updated on GitHub/Render for online
bot conversation changes. Solo uses the APK's local server and needs no internet.
Local checks cover message pacing and attack timers, and render long messages
in English, Malay, Chinese and Tamil at three sizes and three text settings.
