#ifndef FEATURE_FUNCS
#define FEATURE_FUNCS

#include <stdlib.h>
#include <string>
#include <sstream>
#include <assert.h>
#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>

//useless!  these are some alternative to straightforward pointwise mult
//used in the cross-correlation step.
//They are slower
#include <valarray>
#include <gsl/gsl_vector.h>

#include "gaussian/gaussianiir2d.h"

#include "gostate.h"

class FeatureFuncs {
public :

    //the primary method. Make binary features, futz with them, cross corr
    static float evaluateState( GoState* gs );

    //if it weren't for testing in go.cpp, these could be private, I think

    //take a GoState and fill the 'features' array.
    //The features array represenets NFEATURES DIMENSIONxDIMENSION boards
    //The board for each feature is layed out linearly in row-major order 
    //(use featureIX to help w/ indexing)
    static void setBinaryFeatures( GoState* gs, float* features );

    //input_board and output_board both represent DIM x DIM boards.
    //Marks the positions in output_board that are edges in input_board
    //Right now input_board should be an 1/0 array
    //It says float*, but this is superficial and not truly supported by impl
    static void setEdges( float* input_board, float* output_board );

    //cross-correlate binary features with convolved features 
    //  binary_features:  
    //      [binary feat 0], [binary feat 2] ... nfeatures
    //       \           /
    //    DIMENSION x DIMENSION
    //          
    //  convolved features:
    //  [
    //    [convolved 1 feat 1], [convolved 1 feat 2], ... nfeatures
    //    [convolved 2 feat 1], [convolved 2 feat 2], ... nfeatures
    //    ...
    //    n_convolutions
    //  ]
    //results array should be NFEATURES * NFEATURES * NCONVOLUTIONS floats
    static void crossCorrelate( float* binary_features, 
                                float* convolved_features, 
                                float* results ); 

    //helper for gaussian kernling
    //take a board of width,heigth and print it as csv to filename
    static void board2csv( float* board, int size, int width, string filename );
    
    //return the manhattan distance of the closest <friend,foe>
    static pair<int,int> getManhattanDistPair( GoState* gs, int ix );

    //Take the feature number and the ix into a BIGDIMxBIGDIM board in
    //row-major order.  Outputs the correct spot in the 'features' array
    static int featureIX( int feature, int ix );
    
    //to_fill is an int[8] that gets filled with the neighbors of ix in board
    //offboards are -1, otherwise neighbors are 0 or 1
    static void neighborValues( int* to_fill, int* board, int ix );

    //takes a pattern and an input array 'neighbors' (generated by 
    //neighborValues). Returns whether there is an acceptable match
    //TODO: return a float
    //TODO: encapsulate the pattern array into a class?  And have neighbor
    //values return one of those instead?
    static bool matchesPattern( int* neighbors, int* pattern );

    //returns 1 if on N border
    //        2 if on W border
    //        3 if on E border
    //        4 if on S border
    //        12 if on NW corner
    //        13 if on NE corner
    //        42 if on SW corner
    //        43 if on SE corner  
    //for use on boards without apron/buffer 
    static int getSide( int ix );

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    //some benchmarking to determine how best to do the point-wise mult 
    // and addition
    // [1,2,3,4] .* [5,6,7,8]
    // vs
    // [1,5,2,6,3,7,4,8] and timesing adjacent elements together.
    // full scale interleaving is faster (about 2x) but will incur
    // extra overhead to get arrays into the correct form
    // additionally, it will necessitate un-modulating the code a bit,
    // as they will all need to update the same giant array
    // also, the giant array will be giant, a big use of memory
    // 19x19x2 for each feature pair, 31x31 pairs, x4-9 convolved features 
    // = 2775368 - 6244578 floats = 4 bytes = 8,326,104 - 18,733,734 ~8MB-19MB
    //
    // wait yeah this overhead will be big.  can't put things in the right 
    // spot right away.  for gaussian have to take features array as is.
    // would have to copy it, this overhead is already atleast the price of 
    // the naive way, 
    //
    // GPU will work, but won't be able to move it to the cluster
    // also if doing root parallelization, or multiple games in parallel,
    // only one can use GPU at a time.  So really not doing much overall,
    // especially given additional complexity and programmer overhead
    //
    // like always, let's start with naive, non-interleaved solution
    // and go from there.
    static float naivePointMult( float* a, float* b, int size );
    static float interleavedPointMult( float* a, int size );



};


#endif
