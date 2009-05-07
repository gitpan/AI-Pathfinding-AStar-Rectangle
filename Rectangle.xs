#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#define cxinc() Perl_cxinc(aTHX)
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

inline bool is_hash(SV *x){
    return SvTYPE(x) == SVt_PVHV;
}

struct map_item{
    int g;
    int h;
    int k;
    char prev;
    char open;
    char closed;
    char reserved[1];
};
struct map_like{
    unsigned int width;
    unsigned int height;
    signed int start_x;
    signed int start_y;
    signed int current_x;
    signed int current_y;
    unsigned char map[];
};


typedef struct map_like * pmap;
static  int path_weigths[10]={50,14,10,14,10,50,10,14,10,14};

bool check_options(pmap map, HV *opts){
    if (!hv_exists(opts, "width", 5))
        return 0;
    if (!hv_exists(opts, "height", 6))
        return 0;

    SV ** item;
    item = hv_fetch(opts, "width", 5, 0);
    map->width = SvIV(*item);
    item = hv_fetch(opts, "height", 6, 0);
    map->height = SvIV(*item);
    return 1;
}

void
inline init_move_offset(pmap map, int * const moves, int trim){
    const int dx = 1;
    const int dy = map->width + 2;
    moves[0] = 0;
    moves[5] = 0;
    moves[1] = -dx - dy;
    moves[2] =     - dy;
    moves[3] = +dx - dy;
    moves[4] = -dx     ;
    moves[6] = +dx     ;
    moves[7] = -dx + dy;
    moves[8] =     + dy;
    moves[9] = +dx + dy;
    if (trim){
        moves[0] = moves[8];
        moves[5] = moves[9];
    }
}

bool
inline on_the_map(pmap newmap, int x, int y){
    if (x< newmap->start_x  ||y< newmap->start_y ){
        return 0;
    }
    else if (x - newmap->start_x >= newmap->width || y - newmap->start_y >= newmap->height){
        return 0;
    }
    return 1;
}
int 
inline get_offset(pmap newmap, int x, int y){
    return ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
}

int 
inline get_offset_abs(pmap newmap, int x, int y){
    return ( (y + 1)*(newmap->width+2) + (x + 1));
}
void
inline get_xy(pmap newmap, int offset, int *x,int *y){
   *x = offset % ( newmap->width + 2) + newmap->start_x - 1;
   *y = offset / ( newmap->width + 2) + newmap->start_y - 1;
}

MODULE = AI::Pathfinding::AStar::Rectangle		PACKAGE = AI::Pathfinding::AStar::Rectangle		

void 
new(self, options)
SV * self;
SV * options;
    INIT:
    int width;
    int height;
    SV * object;
    struct map_like re_map;
    pmap newmap;
    int map_size;
    SV *RETVALUE;
    PPCODE:
        if (!(SvROK(options) && (is_hash(SvRV(options))))){
            croak("Not hashref: USAGE: new( {width=>10, height=>20})");            
        }
        if (!check_options(&re_map, (HV *) SvRV(options))){
            croak("Not enougth params: USAGE: new( {width=>10, height=>20})");            
            croak("Fail found mandatory param");
        }
        object  = sv_2mortal(newSVpvn("",0));


        SvGROW(object, map_size = sizeof(struct map_like)+(re_map.width + 2) * (re_map.height+2));

        newmap = (pmap) SvPV_nolen(object);

        Zero(newmap, map_size, char);

        newmap->width = re_map.width;
        newmap->height = re_map.height;
        SvCUR_set(object, map_size);
        RETVALUE = sv_2mortal( newRV_inc(object ));
        sv_bless(RETVALUE, gv_stashpv("AI::Pathfinding::AStar::Rectangle", GV_ADD));
        XPUSHs(RETVALUE);

void 
start_x(self, newpos_x = 0)
SV * self;
int newpos_x;
    INIT:
    pmap newmap;

    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (items>1){
            newmap->start_x = newpos_x;
            XPUSHs(self);
        }
        else {
            mXPUSHi(newmap->start_x);
        }


        

void 
start_y(self, newpos_y = 0)
SV * self;
int newpos_y;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (items>1){
            newmap->start_y = newpos_y;
            XPUSHs(self);
        }
        else {
            mXPUSHi(newmap->start_y);
        }

void 
width(self)
SV * self;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        XPUSHs(sv_2mortal(newSViv(newmap->width)));


        

void 
height(self)
SV * self;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        XPUSHs(sv_2mortal(newSViv(newmap->height)));

void 
last_x(self)
SV * self;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        XPUSHs(sv_2mortal(newSViv(newmap->start_x + (signed)newmap->width -1)));


        

void 
last_y(self)
SV * self;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        XPUSHs(sv_2mortal(newSViv(newmap->start_y + (signed)newmap->height-1)));

void 
set_start_xy(self, x, y)
SV * self;
int x;
int y;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");

        XPUSHs(self);
        newmap = (pmap) SvPV_nolen(SvRV(self));
        newmap->start_x = x;
        newmap->start_y = y;

void 
get_passability(self, x, y)
SV * self;
int x;
int y;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (x - newmap->start_x < 0 ||y - newmap->start_y <0){
            XPUSHs(&PL_sv_no);
        }
        else if (x - newmap->start_x >= newmap->width || y - newmap->start_y >= newmap->height){
            XPUSHs(&PL_sv_no);
        }
        else {
            int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
            XPUSHs( sv_2mortal(newSViv( newmap->map[offset])));
        }

void 
set_passability(self, x, y, value)
SV * self;
int x;
int y;
int value;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (x - newmap->start_x <0 ||y - newmap->start_y <0){
            warn("x=%d,y=%d outside map", x, y);
            XPUSHs(&PL_sv_no);
        }
        else if (x - newmap->start_x >= newmap->width || y - newmap->start_y >= newmap->height){
            warn("x=%d,y=%d outside map", x, y);
            XPUSHs(&PL_sv_no);
        }
        else {
            int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
            newmap->map[offset] = value;
        }

void
foreach_xy(self, block)
SV * self;
SV * block;
PROTOTYPE: $&
CODE:
{
    dVAR; dMULTICALL;
    pmap newmap;
    int x,y;
    GV *agv,*bgv,*gv;
    HV *stash;
    I32 gimme = G_VOID;
    SV **args = &PL_stack_base[ax];
    SV *x1, *y1, *value;
    AV *argv;

    CV *cv;
    if (!sv_isobject(self))
        croak("Need object");
    newmap = (pmap) SvPV_nolen(SvRV(self));
    cv = sv_2cv(block, &stash, &gv, 0);
    agv = gv_fetchpv("a", TRUE, SVt_PV);
    bgv = gv_fetchpv("b", TRUE, SVt_PV);
    SAVESPTR(GvSV(agv));
    SAVESPTR(GvSV(bgv));
    SAVESPTR(GvSV(PL_defgv));
    x1 = sv_newmortal();
    y1 = sv_newmortal();

    SAVESPTR(GvAV(PL_defgv));
    if (0){
        argv = newAV();
        av_push(argv, newSViv(10));
        av_push(argv, newSViv(20));
        sv_2mortal((SV*) argv);
        GvAV(PL_defgv) = argv;
    }
    value = sv_newmortal();
    GvSV(agv) = x1;
    GvSV(bgv) = y1;
    GvSV(PL_defgv)  = value;
    PUSH_MULTICALL(cv);
    if (items>2){
        for(y =newmap->height-1 ; y>=0; --y){
            for (x = 0; x < newmap->width; ++x){
                sv_setiv(x1,x + newmap->start_x);
                sv_setiv(y1,y + newmap->start_y);
                sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
                MULTICALL;

            }
        }

    }
    else {
        for(y =0; y< newmap->height; ++y){
            for (x = 0; x < newmap->width; ++x){
                sv_setiv(x1,x + newmap->start_x);
                sv_setiv(y1,y + newmap->start_y);
                sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
                MULTICALL;

            }
        }
    }
    POP_MULTICALL;
    XSRETURN_EMPTY;
}

void
foreach_xy_set (self, block)
SV * self;
SV * block;
PROTOTYPE: $&
CODE:
{
    dVAR; dMULTICALL;
    pmap newmap;
    int x,y;
    GV *agv,*bgv,*gv;
    HV *stash;
    I32 gimme = G_VOID;
    SV **args = &PL_stack_base[ax];
    SV *x1, *y1, *value;

    CV *cv;
    if (!sv_isobject(self))
        croak("Need object");
    newmap = (pmap) SvPV_nolen(SvRV(self));
    cv = sv_2cv(block, &stash, &gv, 0);
    agv = gv_fetchpv("a", TRUE, SVt_PV);
    bgv = gv_fetchpv("b", TRUE, SVt_PV);
    SAVESPTR(GvSV(agv));
    SAVESPTR(GvSV(bgv));
    SAVESPTR(GvSV(PL_defgv));
    x1 = sv_newmortal();
    y1 = sv_newmortal();
    value = sv_newmortal();
    GvSV(agv) = x1;
    GvSV(bgv) = y1;
    GvSV(PL_defgv)  = value;
    PUSH_MULTICALL(cv);
    for(y =0; y< newmap->height; ++y){
        for (x = 0; x < newmap->width; ++x){
            sv_setiv(x1,x + newmap->start_x);
            sv_setiv(y1,y + newmap->start_y);
            sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
            MULTICALL;
            
            newmap->map[get_offset_abs(newmap, x, y)] = SvIV(*PL_stack_sp);
        }
    }
    POP_MULTICALL;
    XSRETURN_EMPTY;
}

void
path_goto(self, x, y, path)
SV * self;
int x;
int y;
char *path;
    INIT:
    pmap newmap;
    char * position;
    int moves[10];
    int gimme;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
        init_move_offset(newmap, moves, 0);
        position = path;

        int weigth = 0;
        while(*position){
            if (*position < '0' || *position>'9'){
                goto last_op;
            };


            offset+= moves[ *position - '0'];
            weigth+= path_weigths[ *position - '0' ];
            ++position;
        }
        gimme = GIMME_V;
        if (gimme == G_ARRAY){
            int x,y;
            int norm;
            norm = offset ;

            x = norm % ( newmap->width + 2) + newmap->start_x - 1;
            y = norm / ( newmap->width + 2) + newmap->start_y - 1;
            mXPUSHi(x);
            mXPUSHi(y);
            mXPUSHi(weigth);
        }
        last_op:;

void 
draw_path_xy( self, x, y, path, value )
SV * self;
int x;
int y;
char *path;
int value;
    INIT:
    pmap newmap;
    char *position;
    int moves[10];
    int moves_x[10];
    int moves_y[10];
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if ( !on_the_map(newmap, x, y) ){
            croak("start is outside the map");
        }
        else {
            int offset = get_offset(newmap, x, y);
            const int max_offset   =  get_offset_abs( newmap, newmap->width, newmap->height);
            const int min_offset   =  get_offset_abs( newmap, 0, 0);
            init_move_offset(newmap, moves,0);
            newmap->map[offset] = value;
            position = path;
            while(*position){
                if (*position < '0' || *position>'9'){
                    croak("bad path: illegal symbols");
                };
                

                offset+= moves[ *position - '0'];
                if (offset > max_offset || offset < min_offset || 
                    offset % (newmap->width + 2) == 0 ||
                    offset % (newmap->width + 2) == newmap->width + 1 ){
                    croak("path otside map");
                }
                newmap->map[offset] = value;
                ++position;
            }       
            get_xy(newmap, offset, &x, &y);
            mXPUSHi(x);
            mXPUSHi(y);
        }

void 
is_path_valid(self, x, y, path)
SV * self;
int x;
int y;
char *path;
    INIT:
    pmap newmap;
    char * position;
    int moves[10];
    int gimme;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (x< newmap->start_x  ||y< newmap->start_y ){
            XPUSHs(&PL_sv_no);
        }
        else if (x - newmap->start_x >= newmap->width || y - newmap->start_y >= newmap->height){
            XPUSHs(&PL_sv_no);
        }
        else {
            int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
            int weigth = 0;
            init_move_offset(newmap, moves,0);
            position = path;
            while(*position){
                if (*position < '0' || *position>'9'){
                    XPUSHs(&PL_sv_no);
                    goto last_op;
                };


                offset+= moves[ *position - '0'];
                if (! newmap->map[offset] ){
                    XPUSHs(&PL_sv_no);
                    goto last_op;
                }
                weigth+= path_weigths[ *position - '0' ];
                ++position;
            }
//          fprintf( stderr, "ok");
            gimme = GIMME_V;
            if (gimme == G_ARRAY){
                int x,y;
                int norm;
                norm = offset ;

                x = norm % ( newmap->width + 2) + newmap->start_x - 1;
                y = norm / ( newmap->width + 2) + newmap->start_y - 1;
                mXPUSHi(x);
                mXPUSHi(y);
                mXPUSHi(weigth);
            }            
            XPUSHs(&PL_sv_yes);
        }
        last_op:;

void 
astar( self, from_x, from_y, to_x, to_y )
int from_x;
int from_y;
int to_x;
int to_y;
SV* self;
    INIT:
    pmap newmap;
    char * position;
    int moves[10];
    int gimme;
    struct map_item *layout;
    SV* open_offsets;
    int current, end_offset, start_offset;
    int *opens;
    int opens_start;
    int opens_end;
    static char path_char[8]={'8','1','2','3','4','9','6','7'};
    static int weigths[8]   ={10,14,10,14,10,14,10,14};
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (!on_the_map(newmap, from_x, from_y) || !on_the_map(newmap, to_x, to_y)){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }
        if (! newmap->map[get_offset(newmap, from_x, from_y)] 
            || ! newmap->map[get_offset(newmap, to_x, to_y)]){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }

        
        start_offset = get_offset(newmap, from_x, from_y);
        end_offset = get_offset(newmap, to_x, to_y);

        if (start_offset == end_offset){
            XPUSHs(&PL_sv_no);
            XPUSHs(&PL_sv_yes);
            goto last_op;
        }

        Newxz(layout, (2+newmap->width) * (2+newmap->height), struct map_item);
        Newx(opens, (2+newmap->width) * (2+newmap->height), int);

        {
            const int dx = 1;
            const int dy = newmap->width + 2;
            int i;

            moves[0] = 0;
            moves[5] = 0;
            moves[1] = -dx - dy;
            moves[2] =     - dy;
            moves[3] = +dx - dy;
            moves[4] = -dx     ;
            moves[6] = +dx     ;
            moves[7] = -dx + dy;
            moves[8] =     + dy;
            moves[9] = +dx + dy;

            moves[0] = moves[8];
            moves[5] = moves[9];


#~ //             for (i = 0; i<10; ++i){
#~ //                 path_char[i] = '0'+i;
#~ //                 weigths[i] = path_weigths[i];
#~ //             }
#~ //             weigths[0] = path_weigths[8];
#~ //             weigths[5] = path_weigths[9];
#~ //             path_char[0] = '8';
#~ //             path_char[5] = '9';
#~ 
        }


        opens_start = 0;
        opens_end   = 0;

        int iter_num = 0;

        current = start_offset;
        layout[current].g      = 0;

        while( current != end_offset){
            layout[current].open   = 0;
            layout[current].closed = 1;
            int i; 
            for(i=0; i<8; ++i){
                int  nextpoint = current + moves[i];
                if ( layout[nextpoint].closed || newmap->map[nextpoint] == 0 )
                    continue;
                int g = weigths[i] + layout[current].g;
                if (layout[nextpoint].open ){
                    if (g < layout[nextpoint].g){
                        int g0;
                        // g0 = layout[nextpoint].g;
                        layout[nextpoint].g = g;
                        layout[nextpoint].k = layout[nextpoint].h + g ;
                        layout[nextpoint].prev = i;
                    }
                }
                else {
                    int x, y;
                    int h;
                    int abs_dx;
                    int abs_dy;
                    get_xy(newmap, nextpoint, &x, &y);
                    

                    layout[nextpoint].open = 1;
                    abs_dx = abs( x-to_x );
                    abs_dy = abs( y-to_y );
                    // layout[nextpoint].h = h = ( abs_dx + abs_dy )*14;
                    h = ( abs_dx + abs_dy )*10; // Manheton
                    #h = 10 * ((abs_dx> abs_dy)?  abs_dx: abs_dy);
                    layout[nextpoint].h = h ; 

                    // layout[nextpoint].h = h = (abs( x - to_x ) + abs(y -to_y))*14;
                    layout[nextpoint].g = g;
                    layout[nextpoint].k = g + h;
                    layout[nextpoint].prev = i;

                    opens[opens_end++] = nextpoint;
                }
            }


            if (opens_start >= opens_end){
                XPUSHs(&PL_sv_no);
                goto free_allocated;
            }


            int index;
            if (0) {
                int min_f; 
                index = opens_start;
                min_f = layout[opens[opens_start]].g  + layout[opens[opens_start]].h; 

                for (i = opens_start+1; i<opens_end; ++i){
                    int f = layout[opens[i]].g  + layout[opens[i]].h;
                    if (min_f> f){
                        min_f = f;
                        index = i;
                    }
                }

            }
            else {
                int min_k; 
                index = opens_start;
                min_k = layout[opens[opens_start]].k ; // + layout[opens[opens_start]].h; 

                for (i = opens_start+1; i<opens_end; ++i){
                    int k = layout[opens[i]].k ; // + layout[opens[i]].h;
                    if (min_k> k){
                        min_k = k;
                        index = i;
                    }
                }
            }
            current = opens[index];
            opens[index] = opens[opens_start];
            ++opens_start;
            iter_num++;
        }

        int i;
        SV* path;
        char *path_pv;
        STRLEN path_len;

        path = sv_2mortal(newSVpvn("",0));

        while(current != start_offset){
            int i = layout[current].prev;
            sv_catpvn_nomg(path, &path_char[i], 1);
            current -= moves[i];
        };
        path_pv = SvPV( path, path_len);
        for(i=0; i<path_len/2; ++i){
            char x;
            x = path_pv[path_len-i-1];
            path_pv[path_len - i - 1] = path_pv[i];
            path_pv[ i ] = x;
        }
        if (GIMME_V == G_ARRAY){
            XPUSHs(path);
            XPUSHs(&PL_sv_yes);
        }
        else {
            XPUSHs(path);
        }

        free_allocated:;
        (void) Safefree(opens);
        (void) Safefree(layout);
        
        last_op:; // last resort Can't use return
