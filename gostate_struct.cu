#include "gostate_struct.h"
#include "stdio.h"

GoStateStruct::GoStateStruct( ){
    player = BLACK;
    action = 42;
    num_open = 0;
    frozen_num_open = 0;
    for( int i=0; i<BOARDSIZE; i++ ){
        if( i < BIGDIM || 
            i % BIGDIM == 0 || 
            i % BIGDIM == BIGDIM-1 || 
            i >= BOARDSIZE - BIGDIM ) {
                board[i] = OFFBOARD;
                frozen_board[i] = OFFBOARD;
        }
        else{
            board[i] = EMPTY; 
            frozen_board[i] = EMPTY;
            num_open++;
        }
    }
    for( int i=0; i<PAST_STATE_SIZE; i++ ){
        past_boards[i] = OFFBOARD;
    }
    for( int i=0; i<NUM_PAST_STATES; i++ ){
        past_actions[i] = -1;
        past_players[i] = OFFBOARD;
    }

}

int GoStateStruct::numElementsToCopy(){
    return 7;
}
/*
void GoStateStruct::cudaAllocateAndCopy( void** pointers ){
    int* dev_action;
    int* dev_num_open;
    char* dev_board;
    char* dev_player;
    char* dev_past_boards;
    char* dev_past_players;
    int* dev_past_actions;

    cudaMalloc( (void**)&dev_action, sizeof(int) );
    cudaMemcpy( dev_action, &(action), sizeof(int), cudaMemcpyHostToDevice );
    pointers[0] = (void*) dev_action;

    cudaMalloc( (void**)&dev_num_open, sizeof(int) );
    cudaMemcpy( dev_num_open, &(num_open), sizeof(int), cudaMemcpyHostToDevice );
    pointers[1] = (void*) dev_num_open;

    cudaMalloc( (void**)&dev_board, BOARDSIZE*sizeof(char) );
    cudaMemcpy( dev_board, board, BOARDSIZE*sizeof(char), cudaMemcpyHostToDevice );
    pointers[2] = (void*) dev_board;

    cudaMalloc( (void**)&dev_player, sizeof(char) );
    cudaMemcpy( dev_player, &(player), sizeof(char), cudaMemcpyHostToDevice );
    pointers[3] = (void*) dev_player;

    cudaMalloc( (void**)&dev_past_boards, sizeof(char)*BOARDSIZE );
    cudaMemcpy( dev_past_boards, past_boards, BOARDSIZE*sizeof(char), cudaMemcpyHostToDevice );
    pointers[4] = (void*) dev_past_boards;

    cudaMalloc( (void**)&dev_past_players, sizeof(char)*BOARDSIZE );
    cudaMemcpy( dev_past_players, past_players, BOARDSIZE*sizeof(char), cudaMemcpyHostToDevice );
    pointers[5] = (void*) dev_past_players;
    
    cudaMalloc( (void**)&dev_past_actions, sizeof(char)*BOARDSIZE );
    cudaMemcpy( dev_past_actions, past_actions, BOARDSIZE*sizeof(char), cudaMemcpyHostToDevice );
    pointers[6] = (void*) dev_past_actions;
}*/

void GoStateStruct::freezeBoard(){
    for( int i=0; i<BOARDSIZE; i++ ){
        frozen_board[i] = board[i];
    }
    frozen_num_open = num_open;
}

void GoStateStruct::thawBoard(){
    for( int i=0; i<BOARDSIZE; i++ ){
        //setBoard(i, frozen_board[i]);
        board[i] = frozen_board[i];
    }
    num_open = frozen_num_open;
}

void* GoStateStruct::copy(){
    GoStateStruct* s = (GoStateStruct*) malloc(sizeof(GoStateStruct));
    for( int i=0; i<BOARDSIZE; i++ ){
        s->board[i] = board[i];
        s->frozen_board[i] = frozen_board[i];
    }

    s->num_open = num_open;
    s->player = player;
    s->action = action;

    for( int i=0; i<PAST_STATE_SIZE; i++){
        s->past_boards[i] = past_boards[i];
    }
    for( int i=0; i<NUM_PAST_STATES; i++ ){
        s->past_players[i] = past_players[i];
        s->past_actions[i] = past_actions[i];
    }
    return (void*) s; 
};

char GoStateStruct::flipColor( char c ){
    assert( c == WHITE || c == BLACK );
    return (c == WHITE) ? BLACK : WHITE;
}

bool GoStateStruct::sameAs( char* other_board, char player ){
    if( player != player ){
        return false;
    }
    else{
        for( int i=0; i < BOARDSIZE; i++ ){
            if( board[i] != other_board[i] ){
                return false;
            }
        }
        return true;
    }
}

//bool GoStateStruct::sameAs( GoStateStruct* gss2 ){
//return sameAs( gss2->board, gss2->player );
//}

void GoStateStruct::togglePlayer() {
    (player == WHITE) ? player = BLACK : player = WHITE;
}

string GoStateStruct::boardToString( char* board ){
    string out;
    for( int i=0; i<BOARDSIZE; i++ ){
        if(      board[i] == BLACK    ){ out += "x"; }
        else if( board[i] == WHITE    ){ out += "o"; }
        else if( board[i] == OFFBOARD ){ out += "_"; }
        else if( board[i] == EMPTY    ){ out += "."; }
        else{   
            printf( "offending pos is %d, %c\n", i, board[i] );
            assert(false); }

        out += " ";
        if( i % BIGDIM == BIGDIM-1 ){
            out += "\n";
        }
    }
    return out;
}

string GoStateStruct::toString(){
    string out;

    stringstream ss;
    ss << "Player: " << player << endl;
    out += ss.str();
    
    out += boardToString( board );
    
    ss << "Action : " << action << endl;
    out += ss.str();
    return out;
}

int GoStateStruct::neighbor( int ix, DIRECTION dir){
    if( board[ix] == OFFBOARD ){
        return OFFBOARD;
    }
    else{
        if(      dir == N ){  return ix - BIGDIM; }
        else if( dir == S ){  return ix + BIGDIM; }
        else if( dir == E ){  return ix + 1;}
        else if( dir == W ){  return ix -1; }
        else if( dir == NW ){ return ix - BIGDIM - 1; }
        else if( dir == NE ){ return ix - BIGDIM + 1; }
        else if( dir == SW ){ return ix + BIGDIM - 1; }
        else {//if( dir == SE ){ 
            return ix + BIGDIM + 1;
        }
    }
}

int GoStateStruct::ix2action( int ix, char player ){
    int parity;
    if( player == WHITE ){
        parity = 1;
    }
    else{
        parity = -1;
    }
    return ix * parity;
}

int GoStateStruct::action2ix( int action ){
    return abs(action);
}

char GoStateStruct::action2color( int action ){
    assert( action != 0 );
    return (action > 0) ? WHITE : BLACK;
}

int GoStateStruct::ix2color( int ix ){
    return (ix == OFFBOARD) ? OFFBOARD : board[ix];
}

int GoStateStruct::coord2ix( int i, int j ){
    return BIGDIM*i + j;
}

int GoStateStruct::ixColor2Action( int ix, char color ){
    assert( color==WHITE || color==BLACK );
    int mod = (color == WHITE) ? 1 : -1;
    return ix*mod;
}

int GoStateStruct::coordColor2Action( int i, int j, char color ){
    int ix = coord2ix(i,j);
    return ixColor2Action(ix, color);
}

bool GoStateStruct::isPass( int action ){
    return action == PASS;
}

void GoStateStruct::setBoard( int ix, char color ){ 
    if( ix >= BOARDSIZE || board[ix] == OFFBOARD ){ return; } 
 
    if( color == EMPTY ){ 
        num_open++; 
    } 
    else{ 
        //assert( board[ix] == EMPTY ); 
        num_open--; 
    } 
    board[ix] = color; 
}

void GoStateStruct::setBoard( int* ixs, int len, char color ){
    for( int i=0; i<len; i++ ){
        int ix = ixs[i];
        setBoard( ix, color );
    }
}    

void GoStateStruct::neighborsOf( int* to_fill, int ix, int adjacency ){
    //assert( adjacency==4 || adjacency==8 );
    for( int dir=0; dir<adjacency; dir++ ){
        to_fill[dir] = neighbor( ix, (DIRECTION) dir);
    }                        
}

void GoStateStruct::filterByColor( 
                    int* to_fill, 
                    int* to_fill_len,
                    int* neighbs,
                    int adjacency,
                    char* color_array,
                    int filter_len ){

    *to_fill_len = 0;
    //int fillix = 0;  
    char ncolor;       
    for(int naix=0; naix<adjacency; naix++){
        int nix = neighbs[naix];
        ncolor = board[nix];
        //cout << "nix: " << nix << " ncolor: " << ncolor << endl;
        for( int caix=0; caix<filter_len; caix++ ){
            if( ncolor == color_array[caix] ){ 
                to_fill[(*to_fill_len)] = nix;
                *to_fill_len = *to_fill_len + 1;
            }
        }
    }
}

bool GoStateStruct::floodFill(  
                int* to_fill,
                int* to_fill_len,
                int epicenter_ix,
                int adjacency,
                char* flood_color_array,
                int filter_len,
                char* stop_color_array,
                int stop_len ){

    marked.clear(); //initBitMask();
    on_queue.clear(); //initBitMask();
    queue.clear(); //initQueue();

    queue.push( epicenter_ix );
    
    int neighbs[adjacency];
    bool stop_color_not_encountered = true;

    while( !queue.isEmpty() ){
        int ix = queue.pop();
        marked.set( ix, true);
 
        neighborsOf(  
                     neighbs, 
                     ix, 
                     adjacency );

        //find if there are neighbors that cause flood fill to stop
        int filtered_len = 0;
        filterByColor( 
                       filtered_array,
                       &filtered_len,
                       neighbs,
                       adjacency,
                       stop_color_array,
                       stop_len);

        bool stop_color_is_in_neighbs = filtered_len > 0;
        if( stop_color_is_in_neighbs ){
            stop_color_not_encountered = false;
            break;
        }
        else {
            //find connected neighbors
            filterByColor( 
                           filtered_array,
                           &filtered_len,
                           neighbs,
                           adjacency,
                           flood_color_array,
                           filter_len );
            //see if connector neighbors are already in marked
            //if not, add them
            assert( filtered_len <= 4 );
            for( int faix=0; faix < filtered_len; faix++ ){
                int ix = filtered_array[faix];
                if( !marked.get( ix) && !on_queue.get( ix) ){
                    queue.push(ix);
                    on_queue.set( ix,true);
                }
            }
        }
    }

    //populate to_fill; kinda of unnecassay just did to keep use pattern same
    int i = 0;
    for( int j=0; j<BOARDSIZE; j++ ){
        if( marked.get( j ) ){
            to_fill[i++] = j;
        }
    }
    *to_fill_len = i;

    return stop_color_not_encountered;
}

bool GoStateStruct::isSuicide( int action ){
    char color = action2color( action );
    int ix = action2ix( action );
    //cout << "ix: " << ix << endl;
    int adjacency = 4;

    neighborsOf( neighbor_array, ix, adjacency );

    //same colored neighbors
    char colors[1] = {color};
    int filtered[adjacency+1];
    int filtered_len;
    filterByColor( filtered, &filtered_len,
                   neighbor_array, adjacency,
                   colors, 1 );
    //add the origial ix to the filtered array
    filtered[filtered_len] = ix;
    filtered_len++;


    //floodfill each neighbor stopping if an adjacent EMPTY is found
    //If one of the groups has no liberties, the move is illegal
    //(Not considering moves that make space by capturing opponent first
    // these pieces should be removed beforehand)
    bool left_with_no_liberties = false;
    //set<int> marked;
    BitMask marked;

    char stop_array[1] = {EMPTY};

    for( int i=0; i < filtered_len; i++ ){
        int nix = filtered[i];
        //cout << "nix: " << nix << endl;
        if( marked.get( nix ) ){ continue; }

        int flood_len = 0;
        bool fill_completed = 
        floodFill( floodfill_array, &flood_len,
                   nix,
                   adjacency,
                   colors, 1,
                   stop_array, 1 );
        //delete colors;

        if( fill_completed ){
            for( int j=0; j < flood_len; j++ ){
                //cout << "marking: " << floodfill_array[j] << endl;
                //marked.insert( floodfill_array[j] );
                marked.set( floodfill_array[j], true );
            }
        }
        //cout << "nix: " << nix << "no_liber: " << (flood_len > 0) << endl;
        left_with_no_liberties |= fill_completed;
    }
    //delete filtered;
    //delete stop_array;
    bool surrounded_by_kin = true;
    for( int i=0; i<adjacency; i++ ){
        int ncolor = ix2color( neighbor_array[i] );
        surrounded_by_kin &= ncolor == color || ncolor == OFFBOARD;
    }
                    
    return left_with_no_liberties || surrounded_by_kin;
}

bool GoStateStruct::isDuplicatedByPastState(){
    for( int i=NUM_PAST_STATES-1; i>=0; i-- ){
        int offset = i*BOARDSIZE;
        //int end = begin+BOARDSIZE-1;
        if( sameAs( &past_boards[offset], past_players[i] ) ){
            return true;
        }
    }
    return false;
}

//void GoStateStruct::advancePastStates( GoStateStruct* newest_past_state ){
void GoStateStruct::advancePastStates( char* past_board, 
                                       char past_player,
                                       int past_action ){
    //memcpy?
    int c = PAST_STATE_SIZE-BOARDSIZE;
    //shift last i-1 boards over one
    for( int i=0; i<c; i++ ){
        past_boards[i] = past_boards[i+BOARDSIZE];
    }
    //fill in vacant end spots with the latest board (past_board)
    for( int i=c; i<PAST_STATE_SIZE; i++ ){
        //printf("%d : %c\n", i-c, past_board[i-c]);
        past_boards[i] = past_board[i-c];
    }

    for( int i=0; i<NUM_PAST_STATES-1; i++ ){
        past_players[i] = past_players[i+1];
        past_actions[i] = past_actions[i+1];
    }
    past_players[NUM_PAST_STATES-1] = past_player;
    past_actions[NUM_PAST_STATES-1] = past_action;
    
}
