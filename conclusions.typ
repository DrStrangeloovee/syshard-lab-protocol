#pagebreak()
= Conclusions

+ *Baseline Hardening* has significantly reduced the attack surface kernel-related CVEs (_MDS_#footnote(link("https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/mds.html")), _SSB_#footnote(link("https://nvd.nist.gov/vuln/detail/CVE-2018-3639"))) are patched, and old packages removed. However, immediate attention is needed to define _auditd_ rules, purge remaining stale packages, address deleted-file handles and block the _ICMP_ timestamp vulnerability. Until these are closed, the system's security still shows some room for improvement.

+ *SSH Hardening* is effectively implemented: only _Protocol 2_ is allowed, _root_ login and password authentication are disabled and _DevSec_ baseline defaults (strong algorithms and ciphers) are in place. As _Lynis_ no longer reports SSH weaknesses, the daemon is considered hardened.

+ *Security Updates Management* is fully automated via the _unattended-upgrades_ mechanism, scheduling daily security-only patches and logging all events. The addition of _apt-listchanges_ ensures administrators can verify which critical _CVEs_ are applied. This approach minimizes the exposure window, keeping the system up-to-date without manual oversight.

+ *Podman* deployment introduces new areas requiring actions: container-specific _audit_ rules, dedicated storage partitions, and strict _TLS_/socket permissions if exposed. While _Podman's_ rootless design reduces direct _root_ usage, these additional attack surfaces must be mitigated before deploying production containers.

In summary, while the system already benefits from robust hardening measures, addressing the remaining audit findings and properly configuring _Podman_ as outlined will be essential to ensure a fully secure, resilient environment capable of withstanding threats.
