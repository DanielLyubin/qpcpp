##############################################################################
# Product: Makefile for QUTEST DPP-test; QP/C++ on POSIX *Target*
# Last updated for version 6.2.0
# Last updated on  2018-03-16
#
#                    Q u a n t u m     L e a P s
#                    ---------------------------
#                    innovating embedded systems
#
# Copyright (C) 2005-2018 Quantum Leaps, LLC. All rights reserved.
#
# This program is open source software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Alternatively, this program may be distributed and modified under the
# terms of Quantum Leaps commercial licenses, which expressly supersede
# the GNU General Public License and are specifically designed for
# licensees interested in retaining the proprietary status of their code.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Contact information:
# https://www.state-machine.com
# mailto:info@state-machine.com
##############################################################################
#
# examples of invoking this Makefile:
# make -f posix.mak        # make and run the tests in the current directory
# make -f posix.mak HOST=192.168.1.65:6601 # make and run the executable
# make -f posix.mak norun   # only make but not run the tests
# make -f posix.mak clean   # cleanup the build
#

#-----------------------------------------------------------------------------
# project name
#
PROJECT := test_dpp

#-----------------------------------------------------------------------------
# project directories
#

# location of the QP/C++ framework (if not provided in an environemnt var.)
ifeq ($(QPCPP),)
QPCPP := ../../..
endif

# QP port used in this project
QP_PORT_DIR := $(QPCPP)/ports/posix-qutest

# list of all source directories used by this project
VPATH = \
	. \
	$(QPCPP)/src/qf \
	$(QPCPP)/src/qs \
	$(QP_PORT_DIR)

# list of all include directories needed by this project
INCLUDES  = \
	-I. \
	-I$(QPCPP)/include \
	-I$(QPCPP)/src \
	-I$(QP_PORT_DIR)

#-----------------------------------------------------------------------------
# files
#

# C source files...
C_SRCS :=

# C++ source files...
CPP_SRCS := \
	bsp.cpp \
	main.cpp \
	philo.cpp \
	table.cpp \
	test_dpp.cpp

QP_SRCS := \
	qep_hsm.cpp \
	qep_msm.cpp \
	qf_act.cpp \
	qf_actq.cpp \
	qf_defer.cpp \
	qf_dyn.cpp \
	qf_mem.cpp \
	qf_ps.cpp \
	qf_qact.cpp \
	qf_qeq.cpp \
	qf_qmact.cpp \
	qs.cpp \
	qs_64bit.cpp \
	qs_rx.cpp \
	qs_fp.cpp \
	qutest.cpp \
	qutest_port.cpp

LIB_DIRS  :=
LIBS      :=

# defines...
# QP_API_VERSION controls the QP API compatibility; 9999 means the latest API
DEFINES   := -DQP_API_VERSION=9999

#-----------------------------------------------------------------------------
# GNU toolset
#
CC    := gcc
CPP   := g++
#LINK  := gcc    # for C programs
LINK  := g++   # for C++ programs

# basic utilities

MKDIR  := mkdir -p
RM     := rm -f

#============================================================================
# Typically you should not need to change anything below this line

#-----------------------------------------------------------------------------
# build options
#

# combine all the soruces...
CPP_SRCS += $(QP_SRCS)

BIN_DIR := posix

CFLAGS = -g -O -Wall -Wstrict-prototypes -W $(INCLUDES) $(DEFINES) \
	-DQ_SPY -DQ_UTEST -DQ_HOST

CPPFLAGS = -g -O -Wall -W -fno-rtti -fno-exceptions $(INCLUDES) $(DEFINES) \
	-DQ_SPY -DQ_UTEST -DQ_HOST

LINKFLAGS := -Wl,-Map,$(BIN_DIR)/$(PROJECT).map,--cref,--gc-sections

#-----------------------------------------------------------------------------
# combine all the soruces...
INCLUDES  += -I$(QP_PORT_DIR)
LIB_DIRS  += -L$(QP_PORT_DIR)/$(BIN_DIR)

C_OBJS       := $(patsubst %.c,%.o,   $(C_SRCS))
CPP_OBJS     := $(patsubst %.cpp,%.o, $(CPP_SRCS))

TARGET_EXE   := $(BIN_DIR)/$(PROJECT)
C_OBJS_EXT   := $(addprefix $(BIN_DIR)/, $(C_OBJS))
C_DEPS_EXT   := $(patsubst %.o,%.d, $(C_OBJS_EXT))
CPP_OBJS_EXT := $(addprefix $(BIN_DIR)/, $(CPP_OBJS))
CPP_DEPS_EXT := $(patsubst %.o,%.d, $(CPP_OBJS_EXT))

# create $(BIN_DIR) if it does not exist
ifeq ("$(wildcard $(BIN_DIR))","")
$(shell $(MKDIR) $(BIN_DIR))
endif

#-----------------------------------------------------------------------------
# rules
#

.PHONY : clean show test run norun

ifeq ($(MAKECMDGOALS),norun)

all : $(TARGET_EXE)
norun : all

else ifeq ($(MAKECMDGOALS),test)

ifeq ("$(wildcard $(QTOOLS))","")
$(error QTOOLS not found. Please install Qtools and define QTOOLS env. variable)
endif
TCLSH  := tclsh
QUTEST := $(QTOOLS)/qspy/tcl/qutest.tcl

else

all : $(TARGET_EXE) run

endif

$(TARGET_EXE) : $(C_OBJS_EXT) $(CPP_OBJS_EXT)
	$(CPP) $(CPPFLAGS) -c $(QPCPP)/include/qstamp.cpp -o $(BIN_DIR)/qstamp.o
	$(LINK) $(LINKFLAGS) $(LIB_DIRS) -o $@ $^ $(BIN_DIR)/qstamp.o $(LIBS)

# run the test fixture on a POSIX target in a loop, so that it is re-started
# after every test. The loop is terminated by pressing Ctrl-C on the keyboard.
#
run : $(TARGET_EXE)
	set -e; while true; do \
		echo "restarting $(TARGET_EXE)"; \
		$(TARGET_EXE) $(HOST); \
	done

$(BIN_DIR)/%.d : %.cpp
	$(CPP) -MM -MT $(@:.d=.o) $(CPPFLAGS) $< > $@

$(BIN_DIR)/%.d : %.c
	$(CC) -MM -MT $(@:.d=.o) $(CFLAGS) $< > $@

$(BIN_DIR)/%.o : %.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

$(BIN_DIR)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

# include dependency files only if our goal depends on their existence
ifneq ($(MAKECMDGOALS),test)
  ifneq ($(MAKECMDGOALS),clean)
    ifneq ($(MAKECMDGOALS),show)
-include $(C_DEPS_EXT) $(CPP_DEPS_EXT)
    endif
  endif
endif

test :
	$(TCLSH) $(QUTEST) $(TESTS)

clean :
	-$(RM) $(BIN_DIR)/*.o \
	$(BIN_DIR)/*.d \
	$(BIN_DIR)/*.map \
	$(TARGET_EXE)

show :
	@echo PROJECT      = $(PROJECT)
	@echo TARGET_EXE   = $(TARGET_EXE)
	@echo CONF         = $(CONF)
	@echo VPATH        = $(VPATH)
	@echo C_SRCS       = $(C_SRCS)
	@echo CPP_SRCS     = $(CPP_SRCS)
	@echo C_DEPS_EXT   = $(C_DEPS_EXT)
	@echo C_OBJS_EXT   = $(C_OBJS_EXT)
	@echo C_DEPS_EXT   = $(C_DEPS_EXT)
	@echo CPP_DEPS_EXT = $(CPP_DEPS_EXT)
	@echo CPP_OBJS_EXT = $(CPP_OBJS_EXT)
	@echo LIB_DIRS     = $(LIB_DIRS)
	@echo LIBS         = $(LIBS)
	@echo DEFINES      = $(DEFINES)
	@echo HOST         = $(HOST)