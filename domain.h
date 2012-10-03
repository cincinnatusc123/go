#ifndef DOMAIN_H
#define DOMAIN_H

#include <string>
#include <set>
/*#include "action.h"*/

//TODO
//have an action type, instead of strings or ints?
//no simpler the better

class Domain {
    public :
        virtual int getPlayerIx( void* state ) = 0;

        virtual void* copyState( void* state ) = 0;

        virtual void applyAction( void* state, 
                                  int action,
                                  bool side_effects ) = 0;

        //TODO
        //to_fill_len should be defined by the number of players
        //should this be a memember of Domain?
        virtual void getRewards( int* to_fill,
                                 void* state ) = 0;

        virtual std::string randomAction( 
                void* state,
                std::set<std::string> to_exclude ) = 0;

        virtual bool fullyExpanded( int action ) = 0;

        virtual bool isTerminal( void* state ) = 0;
};

#endif