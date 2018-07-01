# adapted from https://delta-xi.net/#056

check:
	-dmesg | grep ACPI | grep supports | grep S3
	-cat /sys/power/mem_sleep | grep deep

suspend:
	echo "deep" | sudo tee /sys/power/mem_sleep
	sudo systemctl suspend -i

doit: /boot/acpi_override
	@echo "add 'GRUB_CMDLINE_LINUX_DEFAULT=\"quiet mem_sleep_default=deep\"' to /etc/default/grub"
	@echo "add 'initrd   /boot/acpi_override ...' to /boot/grub/grub.cfg"

install-deps:
	apt-get install cpio acpica-tools

dsdt.aml:
	sudo cat /sys/firmware/acpi/tables/DSDT | tee $@ > /dev/null

dsdt.dsl: dsdt.aml
	iasl -d dsdt.aml

dsdt.fixed.dsl: dsdt.dsl
	patch --verbose -o $@ < X1C6_S3_DSDT.rcy.patch

%.aml: %.dsl
	iasl -ve -tc $<

kernel/firmware/acpi/dsdt.aml: dsdt.fixed.aml
	mkdir -p $(dir $@)
	cp $< $@

acpi_override: kernel/firmware/acpi/dsdt.aml
	find kernel | cpio -H newc --create > $@

/boot/acpi_override: acpi_override
	sudo cp $< $@

clean:
	rm -f *.dsl *.aml *.hex acpi_override
	rm -rf kernel
