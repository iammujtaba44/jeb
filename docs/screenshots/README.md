# Screenshots

Drop the app screenshots here as PNGs, named so they sort into demo order:

| File                     | Screen                          |
| ------------------------ | ------------------------------- |
| `01-home.png`            | Home dashboard                  |
| `02-budgets.png`         | Budgets (overall + per category)|
| `03-plans.png`           | Plans / net position            |
| `04-settings-money.png`  | Settings — Money                |
| `05-settings-backup.png` | Settings — Backup & Sync        |

Then regenerate the animated demo:

```bash
./docs/make-demo-gif.sh
```

This writes `docs/demo.gif`, which the root `README.md` displays.
