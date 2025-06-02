#pagebreak()

= Analysis Part

With the objectives in place, we can now move on to testing. In the next chapter, we will run a security audit to spot any remaining hardening gaps, check that _SSH_ only uses _Protocol 2_ with key-based login and strong algorithms, confirm that security updates are applied automatically, and the container engine is configured for _rootless_ use. To determine how effectively the implemented measures are in place, we will compare the results to those from the Pre-Analysis phase (see @pre-analysis).

At first glance, the reports and logs clearly indicate that the system has been hardened.

== Lynis audit

In summary, the second _Lynis_ run clearly shows that a more hardened baseline was achieved:
- 15 suggestions removed (fixes to password policies, SSH, core dumps, package cleanup, etc.).
- 4 new suggestions surfaced, corresponding to _auditd_ rules, a deleted-file handle, one remaining stale package, and _NTP_ strata.

- *Authentication & Password Policies*
  - *Before:* Tests _AUTH-9230_, _AUTH-9262_, _AUTH-9286_, _AUTH-9328_ all appeared with suggestions.
  - *After:* Those tests do not generate suggestions *#sym.arrow.r* Password hashing rounds, PAM password-strength modules, and password-aging policies were configured.
- *Audit and Logging*
  - *Before:* _ACCT-9628_ suggested enabling _auditd_.
  - *After:* _ACCT-9628_ is gone (_auditd_ is now enabled), but _ACCT-9630_ appears *#sym.arrow.r* _auditd_ is enabled but has no active rules defined.
  - *Before:* _LOGG-2154_ (e.g. checking log permissions) had suggestions; some of those disappeared.
  - *After:* A new warning from _LOGG-2190_ (“deleted files in use”) needs further investigation.
- *Kernel and Limits*
  - *Before:* _KRNL-5820_ warned to adjust core dump settings in `/etc/security/limits.conf`.
  - *After:* No Suggestion: _KRNL-5820_ *#sym.arrow.r* core dumps were restricted.
- *Package Management*
  - *Before:* _PKGS-7392_ flagged unpurged old packages.
  - *After:* _PKGS-7392_ is gone (packages purged), but _PKGS-7346_ appears *#sym.arrow.r* a different leftover package still needs purging.
- *SSH Hardening*
  - *Before:* _SSH-7408_ suggested disabling _Protocol 1_, _root_ login, password auth.
  - *After:* _SSH-7408_ no longer appears *#sym.arrow.r* _SSH_ configuration was updated accordingly.
- *Networking & NTP*
  - *Before:* _NETW-3200_ flagged _IPv6_ configuration.
  - *After:* _NETW-3200_ suggestion is gone *#sym.arrow.r* _IPv6_ as it was disabled.

#figure(
  image("assets/lynis-analysis.png"),
  caption: [
    Lynis audit results.
  ],
)

#pagebreak()
== OpenVAS report

The applied measures eliminated all medium-rated vulnerabilities. According to the final _OpenVAS_ report, the overall severity dropped to _2.1_, with the only remaining issue being _ICMP Timestamp Reply Information Disclosure (CVE-1999-0524)_#footnote(link("https://nvd.nist.gov/vuln/detail/CVE-1999-0524")). A straightforward mitigation is to block _ICMP_ timestamp requests, allow replies only from trusted hosts, or disable timestamps altogether.

#figure(
  image("assets/openvas-analysis.png"),
  caption: [
    OpenVAS hardened results.
  ],
)

== RustScan

The _RustScan_ output shows two open _TCP_ ports on the host:
- _22/tcp (SSH)_
- _8080/tcp (HTTP-Proxy)_

Both ports are expected to be open: port _8080_ serves the deployed sample web application, while port _22_ is configured for administration via _SSH_.

#figure(
  image("assets/rustscan-analysis.png"),
  caption: [
    Open network ports on hardened system.
  ],
)

#pagebreak()
== Podman report

The conducted _Podman_ security benchmark shows a few areas still open for improvements:
+ *Audit Rules*
  - Every _Podman_‐related binary and directory should be monitored by the Linux audit subsystem *#sym.arrow.r* by adding _Podman_ specific rules.
+ *Separate Partition for Containers*
  - Storing all containers under a dedicated mount on its own partition to ensure they don't fill up the _root_ file system.
+ *Disallow Containers from Gaining New Privileges*
  - Adding the setting `no-new-privileges = true` to the _containers.conf_.
+ *TLS/Certificate Ownership & Permissions*
  - If the _Podman_ socket would be exposed to the network it should be ensured that the registered certificates have the correct ownership and permissions set.

This report shows that further improvements are required before the platform can be considered secure enough for deploying production-ready containers.

#figure(
  image("assets/podman-bench-analysis.png"),
  caption: [
    Podman Security Benchmark.
  ],
)
