#
# (C) Copyright 2000-2009
# Wolfgang Denk, DENX Software Engineering, wd@denx.de.
#

VERSION = 2010
PATCHLEVEL = 03
SUBLEVEL =
EXTRAVERSION =
ifneq "$(SUBLEVEL)" ""
U_BOOT_VERSION = $(VERSION).$(PATCHLEVEL).$(SUBLEVEL)$(EXTRAVERSION)
else
U_BOOT_VERSION = $(VERSION).$(PATCHLEVEL)$(EXTRAVERSION)
endif
TIMESTAMP_FILE = $(obj)include/timestamp_autogenerated.h
VERSION_FILE = $(obj)include/version_autogenerated.h

HOSTARCH := $(shell uname -m | \
	sed -e s/i.86/i386/ \
	    -e s/sun4u/sparc64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/powerpc/ppc/ \
	    -e s/ppc64/ppc/ \
	    -e s/macppc/ppc/)

HOSTOS := $(shell uname -s | tr '[:upper:]' '[:lower:]' | \
	    sed -e 's/\(cygwin\).*/cygwin/')

# Set shell to bash if possible, otherwise fall back to sh
SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	else if [ -x /bin/bash ]; then echo /bin/bash; \
	else echo sh; fi; fi)

export	HOSTARCH HOSTOS SHELL

# Deal with colliding definitions from tcsh etc.
VENDOR=

#########################################################################
# Allow for silent builds
ifeq (,$(findstring s,$(MAKEFLAGS)))
XECHO = echo
else
XECHO = :
endif

#########################################################################
#
# U-boot build supports producing a object files to the separate external
# directory. Two use cases are supported:
#
# 1) Add O= to the make command line
# 'make O=/tmp/build all'
#
# 2) Set environement variable BUILD_DIR to point to the desired location
# 'export BUILD_DIR=/tmp/build'
# 'make'
#
# The second approach can also be used with a MAKEALL script
# 'export BUILD_DIR=/tmp/build'
# './MAKEALL'
#
# Command line 'O=' setting overrides BUILD_DIR environent variable.
#
# When none of the above methods is used the local build is performed and
# the object files are placed in the source directory.
#

ifdef O
ifeq ("$(origin O)", "command line")
BUILD_DIR := $(O)
endif
endif

ifneq ($(BUILD_DIR),)
saved-output := $(BUILD_DIR)

# Attempt to create a output directory.
$(shell [ -d ${BUILD_DIR} ] || mkdir -p ${BUILD_DIR})

# Verify if it was successful.
BUILD_DIR := $(shell cd $(BUILD_DIR) && /bin/pwd)
$(if $(BUILD_DIR),,$(error output directory "$(saved-output)" does not exist))
endif # ifneq ($(BUILD_DIR),)

OBJTREE		:= $(if $(BUILD_DIR),$(BUILD_DIR),$(CURDIR))
SRCTREE		:= $(CURDIR)
TOPDIR		:= $(SRCTREE)
LNDIR		:= $(OBJTREE)
export	TOPDIR SRCTREE OBJTREE

MKCONFIG	:= $(SRCTREE)/mkconfig
export MKCONFIG

ifneq ($(OBJTREE),$(SRCTREE))
REMOTE_BUILD	:= 1
export REMOTE_BUILD
endif

# $(obj) and (src) are defined in config.mk but here in main Makefile
# we also need them before config.mk is included which is the case for
# some targets like unconfig, clean, clobber, distclean, etc.

#ifneq ($(OBJTREE),$(SRCTREE))			#删掉
#obj := $(OBJTREE)/
#src := $(SRCTREE)/
#else
obj :=
src :=
#endif
export obj src

# Make sure CDPATH settings don't interfere
unexport CDPATH

#########################################################################

#ifeq ($(ARCH),powerpc)				#删掉
#ARCH = ppc
#endif

# The "tools" are needed early, so put this first
# Don't include stuff already done in $(LIBS)
SUBDIRS	= tools \
	  examples/standalone \
	  examples/api

.PHONY : $(SUBDIRS)

ifeq ($(obj)include/config.mk,$(wildcard $(obj)include/config.mk))

# Include autoconf.mk before config.mk so that the config options are available
# to all top level build files.  We need the dummy all: target to prevent the
# dependency target in autoconf.mk.dep from being the default.
all:
sinclude $(obj)include/autoconf.mk.dep
sinclude $(obj)include/autoconf.mk

# load ARCH, BOARD, and CPU configuration
include $(obj)include/config.mk
export	ARCH CPU BOARD VENDOR SOC

#(1)
CROSS_COMPILE = arm-linux-

# set default to nothing for native builds
ifeq ($(HOSTARCH),$(ARCH))
CROSS_COMPILE ?=
endif

# load other configuration
include $(TOPDIR)/config.mk

#########################################################################
# U-Boot objects....order is important (i.e. start must be first)

#(2)
OBJS  = cpu/$(CPU)/start.o
#ifeq ($(CPU),i386)                                   #删掉
#OBJS += cpu/$(CPU)/start16.o
#OBJS += cpu/$(CPU)/resetvec.o
#endif
#ifeq ($(CPU),ppc4xx)
#OBJS += cpu/$(CPU)/resetvec.o
#endif
#ifeq ($(CPU),mpc85xx)
#OBJS += cpu/$(CPU)/resetvec.o
#endif

OBJS := $(addprefix $(obj),$(OBJS))

#(3)
LIBS  = lib_generic/libgeneric.a
LIBS += lib_generic/lzma/liblzma.a
LIBS += lib_generic/lzo/liblzo.a
LIBS += $(shell if [ -f board/$(VENDOR)/common/Makefile ]; then echo \
	"board/$(VENDOR)/common/lib$(VENDOR).a"; fi)
LIBS += cpu/$(CPU)/lib$(CPU).a
ifdef SOC
LIBS += cpu/$(CPU)/$(SOC)/lib$(SOC).a
endif
#ifeq ($(CPU),ixp)						#删掉
#LIBS += cpu/ixp/npe/libnpe.a
#endif
LIBS += lib_$(ARCH)/lib$(ARCH).a
LIBS += fs/cramfs/libcramfs.a fs/fat/libfat.a fs/fdos/libfdos.a fs/jffs2/libjffs2.a \
	fs/reiserfs/libreiserfs.a fs/ext2/libext2fs.a fs/yaffs2/libyaffs2.a \
	fs/ubifs/libubifs.a
LIBS += net/libnet.a
LIBS += disk/libdisk.a
LIBS += drivers/bios_emulator/libatibiosemu.a
LIBS += drivers/block/libblock.a
LIBS += drivers/dma/libdma.a
LIBS += drivers/fpga/libfpga.a
LIBS += drivers/gpio/libgpio.a
LIBS += drivers/hwmon/libhwmon.a
LIBS += drivers/i2c/libi2c.a
LIBS += drivers/input/libinput.a
LIBS += drivers/misc/libmisc.a
LIBS += drivers/mmc/libmmc.a
LIBS += drivers/mtd/libmtd.a
LIBS += drivers/mtd/nand/libnand.a
LIBS += drivers/mtd/onenand/libonenand.a
LIBS += drivers/mtd/ubi/libubi.a
LIBS += drivers/mtd/spi/libspi_flash.a
LIBS += drivers/net/libnet.a
LIBS += drivers/net/phy/libphy.a
LIBS += drivers/pci/libpci.a
LIBS += drivers/pcmcia/libpcmcia.a
LIBS += drivers/power/libpower.a
LIBS += drivers/spi/libspi.a
#ifeq ($(CPU),mpc83xx)
#LIBS += drivers/qe/qe.a
#endif
#ifeq ($(CPU),mpc85xx)
#LIBS += drivers/qe/qe.a
#LIBS += cpu/mpc8xxx/ddr/libddr.a
#LIBS += cpu/mpc8xxx/lib8xxx.a
#endif
#ifeq ($(CPU),mpc86xx)
#LIBS += cpu/mpc8xxx/ddr/libddr.a
#LIBS += cpu/mpc8xxx/lib8xxx.a
#endif
LIBS += drivers/rtc/librtc.a
LIBS += drivers/serial/libserial.a
LIBS += drivers/twserial/libtws.a
LIBS += drivers/usb/gadget/libusb_gadget.a
LIBS += drivers/usb/host/libusb_host.a
LIBS += drivers/usb/musb/libusb_musb.a
 
# Apollo +
LIBS += drivers/usb/slave/libusb_slave.a
# Apollo -

LIBS += drivers/usb/phy/libusb_phy.a
LIBS += drivers/video/libvideo.a
LIBS += drivers/watchdog/libwatchdog.a
LIBS += common/libcommon.a
LIBS += libfdt/libfdt.a
LIBS += api/libapi.a
LIBS += post/libpost.a

LIBS := $(addprefix $(obj),$(LIBS))
.PHONY : $(LIBS) $(TIMESTAMP_FILE) $(VERSION_FILE)

LIBBOARD = board/$(BOARDDIR)/lib$(BOARD).a
LIBBOARD := $(addprefix $(obj),$(LIBBOARD))

# Add GCC lib
ifdef USE_PRIVATE_LIBGCC
ifeq ("$(USE_PRIVATE_LIBGCC)", "yes")
PLATFORM_LIBGCC = -L $(OBJTREE)/lib_$(ARCH) -lgcc
else
PLATFORM_LIBGCC = -L $(USE_PRIVATE_LIBGCC) -lgcc
endif
else
PLATFORM_LIBGCC = -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc
endif
PLATFORM_LIBS += $(PLATFORM_LIBGCC)
export PLATFORM_LIBS

# Special flags for CPP when processing the linker script.
# Pass the version down so we can handle backwards compatibility
# on the fly.
LDPPFLAGS += \
	-include $(TOPDIR)/include/u-boot/u-boot.lds.h \
	$(shell $(LD) --version | \
	  sed -ne 's/GNU ld version \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/-DLD_MAJOR=\1 -DLD_MINOR=\2/p')

ifeq ($(CONFIG_NAND_U_BOOT),y)
NAND_SPL = nand_spl
U_BOOT_NAND = $(obj)u-boot-nand.bin
endif

ifeq ($(CONFIG_ONENAND_U_BOOT),y)
ONENAND_IPL = onenand_ipl
U_BOOT_ONENAND = $(obj)u-boot-onenand.bin
ONENAND_BIN ?= $(obj)onenand_ipl/onenand-ipl-2k.bin
endif

__OBJS := $(subst $(obj),,$(OBJS))
__LIBS := $(subst $(obj),,$(LIBS)) $(subst $(obj),,$(LIBBOARD))

#########################################################################
#########################################################################

#（五）、
# Always append ALL so that arch config.mk's can add custom ones
ALL += $(obj)u-boot.srec $(obj)u-boot.bin $(obj)System.map $(U_BOOT_NAND) $(U_BOOT_ONENAND)

all:		$(ALL)

$(obj)u-boot.hex:	$(obj)u-boot
		$(OBJCOPY) ${OBJCFLAGS} -O ihex $< $@

$(obj)u-boot.srec:	$(obj)u-boot
		$(OBJCOPY) -O srec $< $@

$(obj)u-boot.bin:	$(obj)u-boot
		$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

$(obj)u-boot.ldr:	$(obj)u-boot
		$(CREATE_LDR_ENV)
		$(LDR) -T $(CONFIG_BFIN_CPU) -c $@ $< $(LDR_FLAGS)

$(obj)u-boot.ldr.hex:	$(obj)u-boot.ldr
		$(OBJCOPY) ${OBJCFLAGS} -O ihex $< $@ -I binary

$(obj)u-boot.ldr.srec:	$(obj)u-boot.ldr
		$(OBJCOPY) ${OBJCFLAGS} -O srec $< $@ -I binary

$(obj)u-boot.img:	$(obj)u-boot.bin
		./tools/mkimage -A $(ARCH) -T firmware -C none \
		-a $(TEXT_BASE) -e 0 \
		-n $(shell sed -n -e 's/.*U_BOOT_VERSION//p' $(VERSION_FILE) | \
			sed -e 's/"[	 ]*$$/ for $(BOARD) board"/') \
		-d $< $@

$(obj)u-boot.imx:       $(obj)u-boot.bin
		$(obj)tools/mkimage -n $(IMX_CONFIG) -T imximage \
		-e $(TEXT_BASE) -d $< $@

$(obj)u-boot.kwb:       $(obj)u-boot.bin
		$(obj)tools/mkimage -n $(KWD_CONFIG) -T kwbimage \
		-a $(TEXT_BASE) -e $(TEXT_BASE) -d $< $@

$(obj)u-boot.sha1:	$(obj)u-boot.bin
		$(obj)tools/ubsha1 $(obj)u-boot.bin

$(obj)u-boot.dis:	$(obj)u-boot
		$(OBJDUMP) -d $< > $@

GEN_UBOOT = \
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBBOARD) $(LIBS) | \
		sed  -n -e 's/.*\($(SYM_PREFIX)__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
		cd $(LNDIR) && $(LD) $(LDFLAGS) $$UNDEF_SYM $(__OBJS) \
			--start-group $(__LIBS) --end-group $(PLATFORM_LIBS) \
			-Map u-boot.map -o u-boot
$(obj)u-boot:	depend $(SUBDIRS) $(OBJS) $(LIBBOARD) $(LIBS) $(LDSCRIPT) $(obj)u-boot.lds
		$(GEN_UBOOT)
ifeq ($(CONFIG_KALLSYMS),y)
		smap=`$(call SYSTEM_MAP,u-boot) | \
			awk '$$2 ~ /[tTwW]/ {printf $$1 $$3 "\\\\000"}'` ; \
		$(CC) $(CFLAGS) -DSYSTEM_MAP="\"$${smap}\"" \
			-c common/system_map.c -o $(obj)common/system_map.o
		$(GEN_UBOOT) $(obj)common/system_map.o
endif

$(OBJS):	depend
		$(MAKE) -C cpu/$(CPU) $(if $(REMOTE_BUILD),$@,$(notdir $@))

$(LIBS):	depend $(SUBDIRS)
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(LIBBOARD):	depend $(LIBS)
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(SUBDIRS):	depend
		$(MAKE) -C $@ all

$(LDSCRIPT):	depend
		$(MAKE) -C $(dir $@) $(notdir $@)

$(obj)u-boot.lds: $(LDSCRIPT)
		$(CPP) $(CPPFLAGS) $(LDPPFLAGS) -ansi -D__ASSEMBLY__ -P - <$^ >$@

$(NAND_SPL):	$(TIMESTAMP_FILE) $(VERSION_FILE) $(obj)include/autoconf.mk
		$(MAKE) -C nand_spl/board/$(BOARDDIR) all

$(U_BOOT_NAND):	$(NAND_SPL) $(obj)u-boot.bin
		cat $(obj)nand_spl/u-boot-spl-16k.bin $(obj)u-boot.bin > $(obj)u-boot-nand.bin

$(ONENAND_IPL):	$(TIMESTAMP_FILE) $(VERSION_FILE) $(obj)include/autoconf.mk
		$(MAKE) -C onenand_ipl/board/$(BOARDDIR) all

$(U_BOOT_ONENAND):	$(ONENAND_IPL) $(obj)u-boot.bin
		cat $(ONENAND_BIN) $(obj)u-boot.bin > $(obj)u-boot-onenand.bin

$(VERSION_FILE):
		@( printf '#define U_BOOT_VERSION "U-Boot %s%s"\n' "$(U_BOOT_VERSION)" \
		 '$(shell $(TOPDIR)/tools/setlocalversion $(TOPDIR))' ) > $@.tmp
		@cmp -s $@ $@.tmp && rm -f $@.tmp || mv -f $@.tmp $@

$(TIMESTAMP_FILE):
		@date +'#define U_BOOT_DATE "%b %d %C%y"' > $@
		@date +'#define U_BOOT_TIME "%T"' >> $@

gdbtools:
		$(MAKE) -C tools/gdb all || exit 1

updater:
		$(MAKE) -C tools/updater all || exit 1

env:
		$(MAKE) -C tools/env all MTD_VERSION=${MTD_VERSION} || exit 1

# Explicitly make _depend in subdirs containing multiple targets to prevent
# parallel sub-makes creating .depend files simultaneously.
depend dep:	$(TIMESTAMP_FILE) $(VERSION_FILE) $(obj)include/autoconf.mk
		for dir in $(SUBDIRS) cpu/$(CPU) $(dir $(LDSCRIPT)) ; do \
			$(MAKE) -C $$dir _depend ; done

TAG_SUBDIRS = $(SUBDIRS)
TAG_SUBDIRS += $(dir $(__LIBS))
TAG_SUBDIRS += include

tags ctags:
		ctags -w -o $(obj)ctags `find $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`

etags:
		etags -a -o $(obj)etags `find $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`
cscope:
		find $(TAG_SUBDIRS) -name '*.[chS]' -print > cscope.files
		cscope -b -q -k

SYSTEM_MAP = \
		$(NM) $1 | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		LC_ALL=C sort
$(obj)System.map:	$(obj)u-boot
		@$(call SYSTEM_MAP,$<) > $(obj)System.map

#
# Auto-generate the autoconf.mk file (which is included by all makefiles)
#
# This target actually generates 2 files; autoconf.mk and autoconf.mk.dep.
# the dep file is only include in this top level makefile to determine when
# to regenerate the autoconf.mk file.
$(obj)include/autoconf.mk.dep: $(obj)include/config.h include/common.h
	@$(XECHO) Generating $@ ; \
	set -e ; \
	: Generate the dependancies ; \
	$(CC) -x c -DDO_DEPS_ONLY -M $(HOSTCFLAGS) $(CPPFLAGS) \
		-MQ $(obj)include/autoconf.mk include/common.h > $@

$(obj)include/autoconf.mk: $(obj)include/config.h
	@$(XECHO) Generating $@ ; \
	set -e ; \
	: Extract the config macros ; \
	$(CPP) $(CFLAGS) -DDO_DEPS_ONLY -dM include/common.h | \
		sed -n -f tools/scripts/define2mk.sed > $@.tmp && \
	mv $@.tmp $@

#########################################################################
else	# !config.mk
all $(obj)u-boot.hex $(obj)u-boot.srec $(obj)u-boot.bin \
$(obj)u-boot.img $(obj)u-boot.dis $(obj)u-boot \
$(filter-out tools,$(SUBDIRS)) $(TIMESTAMP_FILE) $(VERSION_FILE) gdbtools \
updater env depend dep tags ctags etags cscope $(obj)System.map:
	@echo "System not configured - see README" >&2
	@ exit 1

tools:
	$(MAKE) -C tools
tools-all:
	$(MAKE) -C tools HOST_TOOLS_ALL=y
endif	# config.mk

.PHONY : CHANGELOG
CHANGELOG:
	git log --no-merges U-Boot-1_1_5.. | \
	unexpand -a | sed -e 's/\s\s*$$//' > $@

include/license.h: tools/bin2header COPYING
	 cat COPYING | gzip -9 -c | ./tools/bin2header license_gzip > include/license.h
#########################################################################

unconfig:
	@rm -f $(obj)include/config.h $(obj)include/config.mk \
		$(obj)board/*/config.tmp $(obj)board/*/*/config.tmp \
		$(obj)include/autoconf.mk $(obj)include/autoconf.mk.dep

%: %_config
	$(MAKE)


#========================================================================
# ARM
#========================================================================

########################################################################
## ARM Integrator boards - see doc/README-integrator for more info.
########################################################################

smdk2410_config	:	unconfig
	@$(MKCONFIG) $(@:_config=) arm arm920t smdk2410 samsung s3c24x0


smdk2440a_config	:	unconfig
	@$(MKCONFIG) $(@:_config=) arm arm920t smdk2440a sun s3c24x0


#########################################################################
#########################################################################
#########################################################################

clean:
	@rm -f $(obj)examples/standalone/82559_eeprom			  \
	       $(obj)examples/standalone/atmel_df_pow2			  \
	       $(obj)examples/standalone/eepro100_eeprom		  \
	       $(obj)examples/standalone/hello_world			  \
	       $(obj)examples/standalone/interrupt			  \
	       $(obj)examples/standalone/mem_to_mem_idma2intr		  \
	       $(obj)examples/standalone/sched				  \
	       $(obj)examples/standalone/smc91111_eeprom		  \
	       $(obj)examples/standalone/test_burst			  \
	       $(obj)examples/standalone/timer
	@rm -f $(obj)examples/api/demo{,.bin}
	@rm -f $(obj)tools/bmp_logo	   $(obj)tools/easylogo/easylogo  \
	       $(obj)tools/env/{fw_printenv,fw_setenv}			  \
	       $(obj)tools/envcrc					  \
	       $(obj)tools/gdb/{astest,gdbcont,gdbsend}			  \
	       $(obj)tools/gen_eth_addr    $(obj)tools/img2srec		  \
	       $(obj)tools/mkimage	   $(obj)tools/mpc86x_clk	  \
	       $(obj)tools/ncb		   $(obj)tools/ubsha1
	@rm -f $(obj)board/cray/L1/{bootscript.c,bootscript.image}	  \
	       $(obj)board/netstar/{eeprom,crcek,crcit,*.srec,*.bin}	  \
	       $(obj)board/trab/trab_fkt   $(obj)board/voiceblue/eeprom   \
	       $(obj)board/armltd/{integratorap,integratorcp}/u-boot.lds  \
	       $(obj)lib_blackfin/u-boot.lds				  \
	       $(obj)u-boot.lds						  \
	       $(obj)cpu/blackfin/bootrom-asm-offsets.[chs]
	@rm -f $(obj)include/bmp_logo.h
	@rm -f $(obj)nand_spl/{u-boot.lds,u-boot-spl,u-boot-spl.map,System.map}
	@rm -f $(obj)onenand_ipl/onenand-{ipl,ipl.bin,ipl.map}
	@rm -f $(ONENAND_BIN)
	@rm -f $(obj)onenand_ipl/u-boot.lds
	@rm -f $(TIMESTAMP_FILE) $(VERSION_FILE)
	@find $(OBJTREE) -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' \
		-o -name '*.o'	-o -name '*.a' -o -name '*.exe'	\) -print \
		| xargs rm -f

clobber:	clean
	@find $(OBJTREE) -type f \( -name .depend \
		-o -name '*.srec' -o -name '*.bin' -o -name u-boot.img \) \
		-print0 \
		| xargs -0 rm -f
	@rm -f $(OBJS) $(obj)*.bak $(obj)ctags $(obj)etags $(obj)TAGS \
		$(obj)cscope.* $(obj)*.*~
	@rm -f $(obj)u-boot $(obj)u-boot.map $(obj)u-boot.hex $(ALL)
	@rm -f $(obj)u-boot.kwb
	@rm -f $(obj)u-boot.imx
	@rm -f $(obj)tools/{env/crc32.c,inca-swap-bytes}
	@rm -f $(obj)cpu/mpc824x/bedbug_603e.c
	@rm -f $(obj)include/asm/proc $(obj)include/asm/arch $(obj)include/asm
	@[ ! -d $(obj)nand_spl ] || find $(obj)nand_spl -name "*" -type l -print | xargs rm -f
	@[ ! -d $(obj)onenand_ipl ] || find $(obj)onenand_ipl -name "*" -type l -print | xargs rm -f

ifeq ($(OBJTREE),$(SRCTREE))
mrproper \
distclean:	clobber unconfig
else
mrproper \
distclean:	clobber unconfig
	rm -rf $(obj)*
endif

backup:
	F=`basename $(TOPDIR)` ; cd .. ; \
	gtar --force-local -zcvf `date "+$$F-%Y-%m-%d-%T.tar.gz"` $$F

#########################################################################
