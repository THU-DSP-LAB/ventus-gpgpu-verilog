include ../../common/make.config

#Can be changed by `make TYPE=CPU`
TYPE = GPU

#C compiler
CC = clang++

SRC = nearestNeighbor.cpp clutils.cpp utils.cpp

CC_FLAGS = -g -O3

EXE = nn.out

release:
	$(CC) $(CC_FLAGS)  $(SRC) -o $(EXE) \
		-I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL \
		-I../util -DTIMING \
		-Wno-unused-result

clean:
	rm -f $(EXE)

run: release
	./$(EXE) filelist.txt -r 5 -lat 30 -lng 90 -t -f  ../../data -p 0 -d 0
