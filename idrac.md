# Integrated Dell Remote Access Controller (iDRAC)

## Firmware updates for iDRAC8

1. Login to iDRAC web interface and remember the system model, e.g. `PowerEdge FC430`,
   and the firmware version, e.g. `2.10.10.10`
2. Open [Dell's support page](https://www.dell.com/support/) and search for the system model
3. Go to `Drivers & Downloads` and set `Category` filter to `iDRAC with Lifecycle controller`
4. Choose e.g. `iDRAC 2.82.82.82` and `View full driver details`
6. Download, read and follow the release notes, e.g. `iDRAC_2.82.82.82_ReleaseNotes_A00.pdf`

   For example, the release notes for `2.82.82.82` state:

   > Updating iDRAC firmware to the current version from versions earlier than 2.70.70.70 is not supported (For example,
   > updating iDRAC firmware from version 2.60.60.60 to version 2.82.82.82 or later is not supported). First update to
   > version 2.70.70.70 or higher, and then update to 2.82.82.82 or later.

   To get older releases of the iDRAC firmware open the full driver details from step 4 and open `Other Available Versions`

5. Download a suitable update package, e.g. `iDRAC-with-Lifecycle-Controller_Firmware_WGNHP_WN64_2.82.82.82_A00_01.EXE`
6. Use [7-Zip](https://www.7-zip.org/) or `7z` to extract the `*.EXE` file
7. Login to iDRAC web interface and on the left navigate to `Overview` > `iDRAC Settings` > `Update and Rollback`
8. At the `Firmware Update` tab, find `Single Update Location`, click on `Browse...`, select file `payload/firmimg.d7`
   which has been extracted from the `*.EXE` file and click on `Update`. Uploading might take a while.
9. Once the upload has been completed, click `Install`. The firmware update takes a while. The host itself will not be
   restarted while iDRAC firmware is updated.
10. Once the firmware update has been completed, follow the steps again to update to the newest iDRAC release.

## Issues

### iDRAC Virtual Console with Plug-in Type `Java` does not work / requires javaws (Java Web Start) and support for Java Network Launch Protocol (JNLP) which is not available.

Update iDRAC firmware to `2.30.30.30` or newer and [enable iDRAC's HTML5 Virtual Console](https://ctrlaltdell.wordpress.com/2016/05/10/html5-console-on-your-idrac7-and-idrac8/):

> After you install the update you enable by going to Server—>Virtual Console
>
> Change the Plug-in Type to HTML5
>
> That’s it! Now click “Launch Virtual Console” on the same page and the HTML5 iDRAC console will launch.

### iDRAC web interface is inaccessible with `Access Error: 400 -- Bad Request`

[This issue is known upstream and a workaround has been suggested](https://www.dell.com/community/Rack-Servers/iDRAC8-2-80-80-80-inaccessible-using-FQDN/m-p/8016181/highlight/true#M9069):

> 2.81.81.81 release have Host header security issue fix ([Link](https://www.dell.com/support/kbdoc/en-us/000183758/dsa-2021-041-dell-emc-idrac-8-security-update-for-a-host-header-injection-vulnerability))
> and launching iDRAC with hostname and FQDN will work by default if hostname/FQDN used is matching with DNS Name and
> Domain configured on iDRAC. If you are using a different name to launch iDRAC than one configured in iDRAC then you
> can add the hostname/FQDN used for launching as an exception by using below racadm command to make it work
>
> To add hostname/FQDN as an exception
> ```
> racadm set idrac.webserver.ManualDNSEntry test.domain.com
> ```
> You can also disable host header check on iDRAC by running below command. This command will disable security fix of
> host header check ([Link](https://www.dell.com/support/kbdoc/en-us/000183758/dsa-2021-041-dell-emc-idrac-8-security-update-for-a-host-header-injection-vulnerability))
>
> ```
> racadm set idrac.webserver.HostHeaderCheck Disabled
> ```

For example, use SSH to apply this workaround and reboot iDRAC:

```sh
ssh root@fqdn racadm set idrac.webserver.HostHeaderCheck Disabled
ssh root@fqdn racadm racreset soft
```
