#
# Makefile for multicycle simulation of ECO32
#

BUILD = ../../build

SRCS = eco32test.v \
       src/toplevel/eco32.v \
       src/clk_rst/clk_rst.v \
       src/cpu/cpu.v \
       src/cpu/cpu_bus.v \
       src/cpu/cpu_core.v \
       src/ram/ram.v \
       src/rom/rom.v \
       src/tmr/tmr.v \
       src/dsp/dsp.v \
       src/kbd/kbd.v \
       src/ser/ser.v
BIN = eco32test

.PHONY:		all install run show clean

all:		show

install:	$(BIN)

$(BIN):		$(SRCS)
		iverilog -Wall -o $(BIN) $(SRCS)

run:		$(BIN)
		@if [ ! -r duration.dat ] ; then \
		  echo "cp defdata/duration.dat ." ; \
		  cp defdata/duration.dat . ; \
		fi
		@if [ ! -r rom.dat ] ; then \
		  echo "cp defdata/rom.dat ." ; \
		  cp defdata/rom.dat . ; \
		fi
		@if [ ! -r kbd.dat ] ; then \
		  echo "cp defdata/kbd.dat ." ; \
		  cp defdata/kbd.dat . ; \
		fi
		@if [ ! -r ser0.dat ] ; then \
		  echo "cp defdata/ser0.dat ." ; \
		  cp defdata/ser0.dat . ; \
		fi
		@if [ ! -r ser1.dat ] ; then \
		  echo "cp defdata/ser1.dat ." ; \
		  cp defdata/ser1.dat . ; \
		fi
		./$(BIN)

show:		run
		gtkwave dump.vcd eco32test.cfg

clean:
		rm -f *~ $(BIN) dump.vcd
		rm -f duration.dat rom.dat
		rm -f kbd.dat dsp.out
		rm -f ser0.dat ser0.out
		rm -f ser1.dat ser1.out
		rm -f src/*~
		rm -f src/toplevel/*~ src/clk_rst/*~ src/cpu/*~
		rm -f src/ram/*~ src/rom/*~ src/tmr/*~
		rm -f src/dsp/*~ src/kbd/*~ src/ser/*~
