= Procedure and Set-Up

In this lab protocol, we outline a systematic approach to hardening a home server for use as a container platform. The focus is exclusively on securing the operating system and the container engine, as well as investigating the attack surface. Additionally, we deploy a simple web application that serves a static page. We do not address internet-facing access here, but a practical option would be to run a VPN server and grant access only to authorized users.
#parbreak()
All configurations are automated and fully reproducible on a fresh installation using Ansible. The chosen operating system is Debian _12.11.0 (bookworm)_#footnote(link("https://www.debian.org/")) - additionally the network install (_netinst_#footnote(link("https://www.debian.org/CD/netinst/")) version of the image was chosen. This decision was made because of the long support provided by the Debian maintainers with backports of security patches and the philosophy of having only stable and well tested software on the system this makes Debian a good choice for our scenario furthermore the choosing the _netinst_ image allows us to start with a minimal set of packages which reduces the complexity by not installing packages which we won't end up using while simultaneously reducing the attack surface.
#parbreak()
Additionally, the _Podman_ container engine will be installed, so the host can serve as a container platform. _Podman_ was chosen over _Docker_ because it supports running containers in rootless mode.
#parbreak()
For the analysis phase a separate _Kali Linux_#footnote(link("https://www.kali.org/")) machine is used which gives us a wide variety of tools to leverage for a more thorough security assessment.
Tools used for the assessment are:
- _Lynis_#footnote(link("https://cisofy.com/lynis/")) to assess the system's security and clearly identify areas for improvement; it will run with elevated privileges to perform a more comprehensive set of tests.
- _OpenVAS_#footnote(link("https://community.greenbone.net/")) is a full-featured vulnerability scanner based off feeds containing known vulnerabilities.
- _RustScan_#footnote(link("https://github.com/bee-san/RustScan")) a modern alternative to _Nmap_#footnote(link("https://nmap.org/")) for port scanning the target.
- _Podman Security Bench_#footnote(link("https://github.com/containers/podman-security-bench")) as test suite based on the _CIS Docker benchmark_#footnote(link("https://www.cisecurity.org/benchmark/docker")).

Although _Lynis_ and _OpenVAS_ overlap in the components they scan, they operate quite differently. _Lynis_ runs locally on the target system with elevated privileges, whereas _OpenVAS_ conducts a remote scan using credentials that grant _root_ access. As a result, we gain both an internal and an external perspective.

#parbreak()
A _Proxmox VE_#footnote(link("https://www.proxmox.com/en/products/proxmox-virtual-environment/overview")) installation is used as a host for the system and a snapshot of the freshly installed system was used to simplify testing and development of the Ansible playbook.

#pagebreak()

== System Description

The target system will be created by using the virtual machine feature of Proxmox, and we assigned the following resources to the system:
#figure(
  image("assets/debian-vm-resources.png"),
  caption: [
    Assigned system resources of virtual machine.
  ],
)

=== Debian installation

After starting the virtual machine we are going to start the installation process but beforehand need to verify the authenticity of the downloaded installation media as described on the official Debian site#footnote("https://www.debian.org/CD/verify").
#figure(
  image("assets/debian-check-sha256.png"),
  caption: [
    Output of verified Debian image.
  ],
)

We run the installation process through the _Graphical install_ option.
#figure(
  image("assets/debian-installer.png"),
  caption: [
    Debian installer menu.
  ],
)
After setting the language, locale, hostname, username and reasonably strong passwords for the _root_ and user account we are asked to partition the hard disk where we choose to manually configure the partition scheme. We are going to apply the following scheme - according to the "Securing Debian Manual"#footnote(link("https://www.debian.org/doc/manuals/securing-debian-manual/ch03s02.en.html")):
- `/home` and `/tmp` because a user has write permission on these and therefore could render the system unstable#footnote(link("https://www.hackinglinuxexposed.com/articles/20031111.html")).
- `/var` to keep in size fluctuating directories separate.

To simplify the process we are choosing the _Create LVM and encrypt_ option which will apply the above-mentioned scheme additionally to encrypting it. After setting the password to decrypt the drive we are presented with the partition scheme shown in @partition-scheme and continue with the installation process.
#figure(
  image("assets/partition-scheme.png"),
  caption: [
    Partition scheme.
  ],
) <partition-scheme>

We don't install any additional software besides the default system tools and the SSH server and finally finish the installation by setting the location of the GRUB bootloader and rebooting into the newly installed system.
#parbreak()
The only account present by default is the superuser _root_. In addition, we've created a non-privileged user named _syshard_ for day-to-day operations and this account does not belong to the _sudoers_ group and therefore cannot perform any administrative tasks without first elevating to root.
To enable _Ansible_ to connect via SSH to the target system we are creating a key pair and transfer the public key to it. While this process could be automated with Ansible too it would require another dependency (_sshpass_#footnote(link("https://anto.online/ssh-connection-type-with-passwords-you-must-install-the-sshpass-program/")) on the remote system to be able to pass the needed SSH password to login and, it was therefore decided to just manually copy the key once and afterward be able to have _Ansible_ connect via SSH keys.
#parbreak()
This is a good moment to take a snapshot as this marks the point of Ansible taking over and automating the rest of the system installation.

#pagebreak()

== Analysis objectives & Questions
// TODO: extend description to what software will be installed/used for what purpose, how these will be configured, at the end of the chapter questions or goal of the analysis (what we intend to find out)/what we explore


+ *Baseline hardening* (according to the _DevSec Hardening Framework Linux baseline_#footnote(link("https://dev-sec.io/baselines/linux/"))
  - *Objective:* Apply well known security recommendations for a Debian 12 host. This includes reducing the attack surface & applying secure configurations.
  - *Question:* Which results will a security audit still find which would require immediate attention?
+ *SSH hardening* (according to the _DevSec Hardening Framework SSH baseline_#footnote(link("https://dev-sec.io/baselines/ssh/"))
  - *Objective:* Harden the SSH service to enforce secure authentication (public key) and disable unsecure options.
  - *Question:* Is the SSH daemon configured to allow only Protocol 2, disable root logins and password authentication, enforce strong key‐exchange algorithms and ciphers?
+ *Security updates management*
  - *Objective:* Ensure the system remains up-to-date with the latest security patches.
  - *Question:* Can we fully automate security updates and verify that critical patches are applied?
+ *Podman deployment*
  - *Objective:* Ensure that deployed containers do not run with _root_ privileges.
  - *Question:* What additional attack surface is introduced by using _Podman_?
/*+ *Minimal attack surface*
  - *Objective:* Remove unneeded software and services.
  - *Questions:* Which default packages and daemons are unnecessary, and how do we remove them?
+ *Network protections*
  - *Objective:* Restrict network traffic to only what's required.
  - *Questions:* Can we define a default-deny firewall policy via _nftables_ and verify it blocks unwanted connections?
+ *Mandatory access control*
  - *Objective:* Use _AppArmor_ to contain services.
  - *Questions:* Are _AppArmor_ profiles enabled by default, and can we load custom enforce-mode rules?
+ *Auditing*
  - *Objective:* Implement robust logging, file-integrity checks, and intrusion detection.
  - *Questions:* Can we automate _auditd_, _AIDE_, and rootkit scans, and schedule/report their findings?
+ *Vulnerability Assessment*
  - *Objective:* Run periodic CVE scans.
  - *Questions:* Does running _OpenVAS_ or a lightweight CVE scanner identify critical flaws out of the box?
*/

== Pre-Analysis <pre-analysis>

Before implementing any hardening measures, it is essential to evaluate the system's current security posture through a comprehensive baseline assessment, ensuring that all subsequent hardening efforts can be measured and that improvements remain both quantifiable and targeted.

Given the minimal installation of our target host, we did not expect to find much. However, _Lynis_ still performs a thorough audit and identifies numerous areas for improvement, while _RustScan_ scans all ports (0–65535) and, as expected, finds only SSH open.

Conveniently, _Lynis_ displays a _Hardening Index_, providing insight into how well the system is secured. This index is derived from the tests _Lynis_ performs and should not be interpreted as a percentage. The report generated by _OpenVAS_ shows that the base installation already contains three medium-rated vulnerabilities, along with three low-rated, information-disclosure misconfigurations. The highest-rated issue carries a _CVSS v3 score_#footnote(link("https://en.wikipedia.org/wiki/Common_Vulnerability_Scoring_System")) of _5.6_.


=== Lynis audit

#figure(
  image("assets/lynis-pre-analysis.png"),
  caption: [
    Lynis audit results.
  ],
)

=== OpenVAS report

#figure(
  image("assets/openvas-pre-analysis.png"),
  caption: [
    OpenVAS scan results.
  ],
)

The three medium rated vulnerabilities are:
+ _The remote host is missing one or more known mitigation(s) on
  Linux Kernel side for the referenced 'MDS - Microarchitectural Data Sampling' hardware
  vulnerabilities._#footnote(link("https://pentest-tools.com/vulnerabilities-exploits/missing-linux-kernel-mitigations-for-mds-microarchitectural-data-sampling-hardware-vulnerabilities_9986"))
+ _Missing Linux Kernel mitigations for 'SSB - Speculative Store Bypass' hardware vulnerabilities_#footnote(link("https://pentest-tools.com/vulnerabilities-exploits/missing-linux-kernel-mitigations-for-ssb-speculative-store-bypass-hardware-vulnerabilities_9991"))
+ _Debian: Security Advisory (DSA-5931-1)_#footnote(link("https://lists.debian.org/debian-security-announce/2025/msg00095.html"))

=== RustScan

#figure(
  image("assets/rustscan-pre-analysis.png"),
  caption: [
    Open network ports on base installation.
  ],
)

== Objectives

=== Preparation <preparation>

Before we start with the actual system hardening we have to prepare the target because the _netinst_ variant doesn't even provide the _sudo_ program which means everything would have to be executed as the _root_ user which wouldn't be optimal. Installing _sudo_ also brings the advantage of logging every call of it. So the following will be automated in a separate initial _Ansible_ role:
+ Installation of _sudo_
+ Adding the _syshard_ user to the _sudoers_ file
Subsequent _Ansible_ roles will then be using _sudo_ to elevate privileges when needed.

To finalize the preparation the system will update the package sources and fetch the latest patches via _apt_#footnote(link("https://packages.debian.org/bookworm/apt")).

=== Baseline hardening

There are many resources covering system hardening of a host and, it is quite a complex topic. We are going to apply some general guidelines provided by the _DevSec Hardening Framework_#footnote(link("https://dev-sec.io/")) which applies various security recommendations. In this chapter only the recommendations in the OS layer is applied.

#figure(
  image("assets/devsec-overview.png"),
  caption: [
    Overview of the coverage of the _DevSec Hardening Framework Baselines_.
  ],
) <devsec-overview>

There are several security improvements#footnote(link("https://dev-sec.io/baselines/linux/")) implemented including:
- Stricter permissions of the _su_ binary.
- Periodic permission and ownership checks of the `/etc/shadow` and `/etc/passwd` files.
- Installation of the _syslog_#footnote(link("https://packages.debian.org/bookworm/syslog-ng")) and _audit_#footnote(link("https://packages.debian.org/bookworm/auditd")) package.

As @devsec-overview displays: logging and monitoring isn't covered by the framework, but this has already been partly covered as shown in @preparation.

#pagebreak()

Additionally the _Uncomplicated Firewall_#footnote("https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29") (_ufw_) was installed and configured.
The implemented steps are:
- Ensure _ufw_ is enabled and running.
- Simultaneous _SSH_ connections are limited.
- _SSH_ connections will be limited to trusted hosts. In this case only to hosts in the _LAN_ and the _VPN_ network to enable secure access from outside.
- For containers the port range 60000-61000 is allowed.

#figure(
  image("assets/ufw-status.png"),
  caption: [
    Overview of enabled _ufw_ rules.
  ],
)

=== SSH hardening

SSH is the preferred way of remotely administering Linux servers. The default configuration grants anyone with valid credentials direct access to the systems command line and makes this a primary target for attacks. In this chapter we are applying several guidelines to secure this important gateway. We are using another _Ansible_ role provided by the _DevSec Hardening Framework_ - the following represents a small subset of rules applied:
- Only allowing Protocol 2 connections for security enhancements#footnote(link("https://www.emtec.com/ssh/ssh-v2.html")).
- Disable all SSH authentication methods except key-based authentication.
- Limit the number of concurrent sessions to minimize the impact of a _Denial of Service_ (DoS) attack against a running SSH daemon.

=== Security updates management

The target host should be updated regularly with the latest security patches. It is a good idea to automate this process to minimize the exposure window following the _Securing Debian Manual_#footnote(link("https://www.debian.org/doc/manuals/securing-debian-manual/security-update.en.html")) suggestion - this is achieved by using _unattended-upgrades_ package and configure it to only apply security related updates. To achieve this the role `hifis.toolkit.unattended_upgrades`#footnote(link("https://galaxy.ansible.com/ui/repo/published/hifis/toolkit/content/role/unattended_upgrades/")) will be used. Which already brings the wanted configuration by only allowing security related patches. The following is a small excerpt of the configuration:
- _unattended_syslog_enable_ = _true_ | Write events to _syslog_ to be in a central location.
- _unattended_apt_daily_upgrade_oncalendar_ = _\*-\*-\* 6:00_ | Time schedule to run update process.
- _unattended_automatic_reboot_ = _false_ | If automatic upgrades need a reboot of the host this isn't done automatically.

#figure(
  image("assets/unattended-upgrades-config.png"),
  caption: [
    Unattended upgrades configured to only allow security patches.
  ],
)
#parbreak()
To assist the update process we are additionally installing the _apt-listchanges_#footnote(link("https://packages.debian.org/bookworm/apt-listchanges")) package which notifies about package updates by email. This ensures that the system administrator is always notified on the update process and if manual intervention is needed.
