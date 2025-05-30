= Procedure and Set-Up

In this lab protocol, we present a systematic approach to hardening a home server that provides Cloud, Media Streaming and File Backup services for family and friends. The protocol focuses exclusively on securing the operating system and the deployed services. We don't deal with the access of the server via the internet; but a viable option would be running a VPN server and only giving access to the allowed users.
#linebreak()
All configurations are automated and fully reproducible on a fresh installation using Ansible. The chosen operating system is Debian _12.11.0 (bookworm)_ - additionally the network install (_netinst_#footnote("https://www.debian.org/CD/netinst/")) version of the image was chosen. This decision was made because of the long support provided by the Debian maintainers with backports of security patches and the philosophy of having only stable and well tested software on the system this makes Debian a good choice for our scenario furthermore the choosing the _netinst_ image allows us to start with a minimal set of packages which reduces the complexity by not installing packages which we won't end up using while simultaneously reducing the attack surface.
#linebreak()
A Proxmox VE installation is used as a host for the system and a snapshot of the freshly installed system was used to simplify testing and development of the Ansible playbook.

== System Description

The system will be created by using the virtual machine feature of Proxmox, and we assigned the following resources to the system:
#figure(
  image("assets/debian-vm-resources.png"),
  caption: [
    Assigned system resources of virtual machine.
  ],
)

=== Debian installation

After starting the virtual machine we are going to start the installation process but beforehand need to verify the authenticity of the downloaded installation media as described on the official Debian site.#footnote("https://www.debian.org/CD/verify").
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
After setting the language, locale, hostname, username and reasonably strong passwords for the _root_ and user account we are asked to partition the hard disk where we choose to manually configure the partition scheme. We are going to apply the following scheme - according to the "Securing Debian Manual"#footnote("https://www.debian.org/doc/manuals/securing-debian-manual/ch03s02.en.html"):
- `/home` and `/tmp` because a user has write permission on these and therefore could render the system unstable#footnote("https://www.hackinglinuxexposed.com/articles/20031111.html").
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
The only account present by default is the superuser _root_. In addition, we've created a non-privileged user named _syshard_ for day-to-day operations and this account does not belong to the sudoers group and therefore cannot perform any administrative tasks without first elevating to root.
To enable _Ansible_ to connect via SSH to the target system we are creating a key pair and transfer the public key to it. While this process could be automated with Ansible too it would require another dependency (_sshpass_#footnote("https://anto.online/ssh-connection-type-with-passwords-you-must-install-the-sshpass-program/")) on the remote system to be able to pass the needed SSH password to login and, it was therefore decided to just manually copy the key once and afterward be able to have _Ansible_ connect via SSH keys.
#parbreak()
This is a good moment to take a snapshot as this marks the point of Ansible taking over and automating the rest of the system installation.

== Analysis objectives & Questions
// TODO: extend description to what software will be installed/used for what purpose, how these will be configured, at the end of the chapter questions or goal of the analysis (what we intend to find out)/what we explore


+ *Security updates management*
  - *Objective:* Ensure the system remains up-to-date with the latest security patches.
  - *Question:* Can we fully automate security updates and verify that critical patches are applied?
+ *Baseline hardening* (according to the _DevSec Hardening Framework_#footnote("https://dev-sec.io/"))
  - *Objective:* Apply well known security recommendations for a Debian 12 host. This includes reducing the attack surface & applying secure configurations.
  - *Question:* Which results will a security audit still find which would require immediate attention?
+ *Security updates management*
  - *Objective:* Ensure the system remains up-to-date with the latest security patches.
  - *Question:* Can we fully automate security updates and verify that critical patches are applied?

// TODO: refine objectives
+ *Minimal attack surface*
  - *Objective:* Remove unneeded software and services.
  - *Questions:* Which default packages and daemons are unnecessary, and how do we remove them?
+ *Access control*
  - *Objective:* Enforce strong authentication and least-privilege access.
  - *Questions:* How do we lock down SSH, user accounts, and sudo to prevent unauthorized entry?
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

// TODO: do we need the following?
- *System hardening according to the _Inspec DevSec Baselines_ *
  + Debian
  + SSH access

== Preparation <preparation>

Before we start with the actual system hardening we have to prepare the target because the _netinst_ variant doesn't even provide the _sudo_ program which means everything would have to be executed as the _root_ user which wouldn't be optimal. Installing _sudo_ also brings the advantage of logging every call of it. So the following will be automated in a separate initial _Ansible_ role:
+ Installation of _sudo_
+ Adding the _syshard_ user to the _sudoers_ file
Subsequent _Ansible_ roles will then be using _sudo_ to elevate privileges when needed.

To finalize the preparation the system will update the package sources and fetch the latest patches via _apt_#footnote("https://packages.debian.org/bookworm/apt").

== Security updates management

The target host should be updated regularly with the latest security patches. It is a good idea to automate this process to minimize the exposure window following the _Securing Debian Manual_#footnote("https://www.debian.org/doc/manuals/securing-debian-manual/security-update.en.html") suggestion - this is achieved by using _unattended-upgrades_ package and configure it to only apply security related updates. To achieve this the role `hifis.toolkit.unattended_upgrades`#footnote("https://galaxy.ansible.com/ui/repo/published/hifis/toolkit/content/role/unattended_upgrades/") will be used. Which already brings the wanted configuration by only allowing security related patches. The following is a small excerpt of the configuration:
- _unattended_syslog_enable_ = _true_ | Write events to _syslog_ to be in a central location.
- _unattended_apt_daily_upgrade_oncalendar_ = _\*-\*-\* 6:00_ | Time schedule to run update process.
- _unattended_automatic_reboot_ = _false_ | If automatic upgrades need a reboot of the host this isn't done automatically.

#figure(
  image("assets/unattended-upgrades-config.png"),
  caption: [
    Unattended upgrades configuration only allowing security patches.
  ],
)
#parbreak()
To assist the update process we are additionally installing the _apt-listchanges_#footnote("https://packages.debian.org/bookworm/apt-listchanges") package which notifies about package updates by email. This ensures that the system administrator is also kept updated on the update process and if manual intervention is needed.

== Baseline hardening

There are many resources covering system hardening of a host and, it is quite a complex topic. We are going to apply some general guidelines provided by the _DevSec Hardening Framework_#footnote("https://dev-sec.io/") which applies various security recommendations. In this chapter only the recommendations in the OS layer is applied.

#figure(
  image("assets/devsec-overview.png"),
  caption: [
    Overview of the coverage of the _DevSec Hardening Framework Baselines_.
  ],
) <devsec-overview>

There are several security improvements#footnote("https://dev-sec.io/baselines/linux/") implemented including:
- Disabling the access

As @devsec-overview displays: logging and monitoring isn't covered by the framework, but this has already been partly covered as shown in @preparation.

// TODO: extend the contents of this chapter

// TODO: reference audit results in next chapter: https://typst.app/docs/reference/model/ref/

