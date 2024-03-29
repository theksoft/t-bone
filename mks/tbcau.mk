# -----------------------------------------------------------------------------
# TEE unitary test application for application client library
# -----------------------------------------------------------------------------

PLATFORM ?= linux
APPNAME := tbcau
LIBAPP := tbapp
LIBCUW := cuw

ifneq "$(PLATFORM)" "win"
  EXE := 
else
  EXE := .exe
endif

# Project folders

INCD := include
SRCD := src

TSTD := test/unit

ROOTD ?= build
BUILD ?= $(ROOTD)/$(PLATFORM)
IMPD ?= $(BUILD)/include
OBJD ?= $(BUILD)/obj
LIBD ?= $(BUILD)/lib
BIND ?= $(BUILD)/bin

DIRS := $(IMPD) $(OBJD) $(LIBD) $(BIND)

# Project source path

vpath %.h $(INCD):$(SRCD):$(TSTD):$(IMPD)
vpath %.hpp $(INCD):$(SRCD):$(TSTD):$(IMPD)
vpath %.cpp $(TSTD)
vpath %.c $(TSTD)
vpath %.o $(OBJD)
vpath %.a $(LIBD)
vpath %$(EXE) $(BIND)

# Project files

CSRC := c_cppstream
CXXSRC := ca_unit_main ca_unit_context
OBJS := $(CXXSRC:%=%.o) $(CSRC:%=%.o) 

#Project options

CINCLUDES := $(INCD) $(SRCD) $(IMPD)
CXXINCLUDES := $(INCD)

CFLAGS := -Wall -Wextra -Werror -Wpedantic -pedantic-errors -fPIC
CXXFLAGS := -Wall -Wextra -Werror -Wpedantic -pedantic-errors -fPIC -std=c++17
LDFLAGS := -fPIC
LIBFLAGS := -L $(LIBD) -l$(LIBAPP)d -l$(LIBCUW) -lcunit -lconfig++ -lboost_thread -lrt -lm -pthread

# Main label

all: dirs $(APPNAME)$(EXE)

# Project file dependencies

DEPD := $(OBJD)/dep
DEPS := $(CXXSRC:%=$(DEPD)/%.d) $(CSRC:%=$(DEPD)/%.d)

$(DEPD)/%.d: %.cpp | $(DEPD)
	@$(CXX) -MM -MP -MT $(OBJD)/$(basename $(<F)).o $(CXXFLAGS) $(CXXINCLUDES:%=-I %) $< > $@

$(DEPD)/%.d: %.c | $(DEPD)
	@$(CC) -MM -MP -MT $(OBJD)/$(basename $(<F)).o $(CFLAGS) $(CINCLUDES:%=-I %) $< > $@

$(DEPD):
	@mkdir -p $@

$(BIND)/$(APPNAME)$(EXE): libcuw.a lib$(LIBAPP)d.a

# Project files build rules

$(OBJD)/%.o: %.c
	$(CC) $(CFLAGS) $(CINCLUDES:%=-I %) -c $< -o $@

$(OBJD)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CXXINCLUDES:%=-I %) -c $< -o $@

# Project targets build

$(BIND)/$(APPNAME)$(EXE): $(OBJS)
	@echo ==== Building $@ [unit test client] ====
	$(CXX) $(LDFLAGS) $^ $(LIBFLAGS) -o $@
	cp $(TSTD)/$(APPNAME).cfg $(BIND)/$(APPNAME).cfg
	cp $(TSTD)/$(APPNAME)s.cfg $(BIND)/$(APPNAME)s.cfg
	@echo =**= Done =**=

# Other project label

dirs: $(DIRS)
$(DIRS):
	@for dir in $(DIRS); do \
	  mkdir -p $$dir; \
	done

clean:
	-@$(RM) $(BIND)/$(APPNAME).cfg
	-@$(RM) $(BIND)/$(APPNAME)$(EXE)
	-@$(RM) $(OBJS:%=$(OBJD)/%)
	-@$(RM) $(DEPS)

cleanall:
	@$(RM) -rf $(DEPD)
	@$(RM) -rf $(DIRS)

.PHONY: all dirs clean cleanall

-include $(DEPS)
