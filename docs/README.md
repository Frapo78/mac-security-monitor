MAC SECURITY MONITOR

Questo sistema controlla cambiamenti nello stato del Mac confrontando
l'output dello script "maccheck" con una baseline salvata.

FILE PRINCIPALI

~/maccheck
    Script che raccoglie lo stato di sicurezza del sistema.

~/maccheck-alert
    Script eseguito automaticamente ogni ora da launchd.

~/.security-baseline/current
    Baseline di riferimento del sistema.

~/Library/LaunchAgents/com.fra.securitycheck.plist
    Job launchd che esegue il controllo ogni ora.

~/securitycheck-status
    Comando rapido per verificare lo stato del monitor.

COME FUNZIONA

1. maccheck raccoglie lo stato del sistema.
2. maccheck-alert confronta lo stato con la baseline.
3. Se cambia qualcosa appare una finestra macOS.

PULSANTI

?
    Mostra questa guida.

Mostra dettagli
    Mostra il report completo nel Terminale.

Aggiorna baseline
    Aggiorna lo stato di riferimento se le modifiche sono legittime.

Disattiva monitor
    Ferma immediatamente il monitor automatico.

COMANDO DI VERIFICA RAPIDA

Per controllare se il sistema di monitoraggio è attivo:

    ~/securitycheck-status

Il comando mostra:

- stato del LaunchAgent
- presenza della baseline
- ultima modifica baseline
- stato dello script monitor
- output iniziale di maccheck

COME RIATTIVARE IL MONITOR

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist

COME DISATTIVARE IL MONITOR

launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist

COME AGGIORNARE MANUALMENTE LA BASELINE

~/maccheck > ~/.security-baseline/current


CONTROLLI EFFETTUATI

Il monitor rileva cambiamenti nei seguenti elementi del sistema:

- LaunchAgents non Apple
- LaunchDaemons
- Applicazioni installate in /Applications
- Porte di rete in ascolto
- Kext non Apple
- Binari con privilegi setuid
- Profili di configurazione macOS

Qualsiasi variazione rispetto alla baseline salvata può generare
una notifica del monitor di sicurezza.


COMANDO RAPIDO

Per controllare rapidamente lo stato del monitor:

    security-monitor

Questo comando è un alias globale che esegue:

    ~/.mac-security-monitor/bin/securitycheck-status

Permette di verificare in pochi secondi:

- stato del LaunchAgent
- presenza della baseline
- stato degli script
- funzionamento del monitor


AGGIORNAMENTO BASELINE

Per aggiornare manualmente la baseline sicurezza:

    security-monitor-update

Questo comando:

1. esegue maccheck
2. aggiorna ~/.mac-security-monitor/baseline/current
3. mostra lo stato del monitor

Usarlo quando si installa software legittimo o si modifica il sistema.

