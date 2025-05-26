
#import "@preview/basic-report:0.2.0": *

#show: it => basic-report(
  doc-category: "SYSHARD",
  doc-title: "Lab Protocol Security Exercise",
  author: ("Marco AUENHAMMER", "Waldermar SCHERER").join(", \n"),
  affiliation: "FH Technikum Wien",
  // logo: image("assets/aerospace-engineering.png", width: 2cm),
  // <a href="https://www.flaticon.com/free-icons/aerospace" title="aerospace icons">Aerospace icons created by gravisio - Flaticon</a>
  language: "en",
  compact-mode: false,
  heading-color: rgb("#8bb31d"),
  heading-font: "Noto Sans",
  it,
)

// Style figure captions to fit the rest of the text
#show figure.caption: it => context [
  *#it.supplement~#it.counter.display()#it.separator*#it.body
]

// Rootpassword: MyRootPassword1!
// Userpassword: MyUserPassword1!
// Encryptpassword: MyEncryptPassword1!


= Introduction

In this lab protocol, we present a systematic approach to hardening a home server that provides Cloud, Media Streaming and File Backup services for family and friends. The protocol focuses exclusively on securing the operating system and the deployed services. We don't deal with the access of the server via the internet; but a viable option would be running a WireGuard server only giving access to the allowed users.
#linebreak()
All configurations are automated and fully reproducible on a fresh installation using Ansible. The chosen operating system is Debian _12.11.0 (bookworm)_ - additionally the network install (_netinst_#footnote("https://www.debian.org/CD/netinst/")) version of the image was chosen. This decision was made because of the long support provided by the Debian maintainers with backports of security patches and the philosophy of having only stable and well tested software on the system this makes Debian a good choice for our scenario furthermore the choosing the _netinst_ image allows us to start with a minimal set of packages which reduces the complexity by not installing packages which we won't end up using while simultaneously reducing the attack surface.
#linebreak()
A Proxmox VE installation is used as a host for the system and a snapshot of the freshly installed system was used to simplify testing and development of the Ansible playbook.

#pagebreak()

= Procedure and Set-Up


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
After setting the language, locale, hostname, username and reasonably strong passwords for the _root_ and _user_ account we are asked to partition the hard disk where we choose to manually configure the partition scheme. We are going to apply the following scheme - according to the "Securing Debian Manual"#footnote("https://www.debian.org/doc/manuals/securing-debian-manual/ch03s02.en.html"):
- `/home` and `/tmp` because a user has write permission on these and therefore could render the system unstable#footnote("https://www.hackinglinuxexposed.com/articles/20031111.html").
- `/var` to keep in size fluctuating directories separate.

To simplify the process we are choosing the "Create LVM and encrypt" option which will apply the above-mentioned scheme additionally to encrypting it. After setting the password to decrypt the drive we are presented with the partition scheme shown in @partition-scheme and continue with the installation process.
#figure(
  image("assets/partition-scheme.png"),
  caption: [
    Partition scheme.
  ],
) <partition-scheme>
#pagebreak()

= Analysis Part

#lorem(80)

#pagebreak()

= Conclusions

#lorem(150)

#pagebreak()

= References

#lorem(90)

#pagebreak()

= Appendix


