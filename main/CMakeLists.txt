# SPDX-License-Identifier: LicenseRef-Source-Available-No-Redistribution
#
# main.c calls espos_start() and nothing else, so espos_core is the only
# component it uses directly. The other two are listed for the build, not for
# main.c: espOS consumers build with IDF's MINIMAL_BUILD, so a component that
# nothing requires is not compiled at all, and espos_start() starts only what
# is in the build. Dropping espos_ble here would build a gateway without the
# gateway; dropping espos_ota, one that can never be updated in the field.
idf_component_register(
    SRCS main.c
    PRIV_REQUIRES espos_core espos_ble espos_ota)
