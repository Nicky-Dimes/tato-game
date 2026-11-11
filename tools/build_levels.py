#!/usr/bin/env python3
"""Builds the campaign's stage files (game/data/levels/*.txt).

Stages are assembled from hand-drawn sections ("chunks"). Each chunk is a
small picture, 15 rows tall once padded, whose ground is on rows 12-14 so
any two chunks join up. The same chunk reads differently in each world
because its letters are mapped to that world's creatures, hazards, powers
and pickups (see WORLDS). The stage lists at the bottom say which chunks
make up each stage, in order.

    python3 tools/build_levels.py

The output files are plain level text and can be edited by hand afterwards
(re-running this script overwrites them).

Chunk letters (besides the built-in terrain / item letters of the level format):
    a b c t   creatures: basic walker, bouncer, charger, tough one
    f F       flying creatures (low, high)        r   ranged creature
    P Q R     food bowls: the world's two powers, and an earlier one
    p q j     charm pickup, fruit pickup, gem     u U  two boost pickups (differ per stage)
    T         this world's own treat (worlds 2-6; a coin in Grassland)
    N         a Treasure Note spot (three per stage are used, the rest become coins)
    Z         the hidden Star                     D   scenery
    x         a prickly static hazard             M V moving platforms (sideways, up-down)
    g y z G H J A K m   world specials (see WORLDS)
    1 2       signposts with this stage's two tips
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "data", "levels")
ROWS = 15
GROUND = "#"


def rows(text):
    lines = text.strip("\n").split("\n")
    width = max(len(l) for l in lines)
    return [l.ljust(width) for l in lines]


def G(n):
    return GROUND * n


# --------------------------------------------------------------------------
# Chunks. Bottom-aligned: the last three rows are the ground.
# --------------------------------------------------------------------------
C = {}

C["start"] = rows("""
 @  1   2     D
%s
%s
%s
""" % (G(16), G(16), G(16)))

C["end"] = rows("""
   D      E
%s
%s
%s
""" % (G(16), G(16), G(16)))

C["cp"] = rows("""
   C   h
%s
%s
%s
""" % (G(10), G(10), G(10)))

C["flat_coins"] = rows("""
     oTo

   D    a      D
%s
%s
%s
""" % (G(18), G(18), G(18)))

C["qblocks"] = rows("""
    ?%%?    o o


       a      p
%s
%s
%s
""" % (G(18), G(18), G(18)))

C["bowl_p"] = rows("""
          o o

  P     a    a   B
%s
%s
%s
""" % (G(20), G(20), G(20)))

C["bowl_q"] = rows("""
          ?


  Q     b    a   B
%s
%s
%s
""" % (G(20), G(20), G(20)))

C["bowl_r"] = rows("""

  R      c     a
%s
%s
%s
""" % (G(18), G(18), G(18)))

C["steps"] = rows("""
              oTo
            ######
        ##########
    ##############   a
%s
%s
%s
""" % (G(24), G(24), G(24)))

C["pit_small"] = rows("""
       oTo

    a          D
#######   ########
#######   ########
#######   ########
""")

C["pit_plat"] = rows("""
         o o

        =====

######         #######
######         #######
######         #######
""")

C["water"] = rows("""
      o   o   o

     q
#####~~~~~~~~~~~~#####
#####~~~~~~~~~~~~#####
######################
""")

C["tower"] = rows("""
        N
      =====

  ====       ====

        ====

    a         b
%s
%s
%s
""" % (G(18), G(18), G(18)))

C["tunnel"] = rows("""
     ##############

        c      oTo
%s
%s
%s
""" % (G(24), G(24), G(24)))

C["hill"] = rows("""
          oTo
        /######\\
       /########\\
%s
%s
%s
""" % (G(24), G(24), G(24)))

C["high_road"] = rows("""
   oooooooo  N
  ==============

     a     b
%s
%s
%s
""" % (G(20), G(20), G(20)))

C["crate_wall"] = rows("""
        o
       BB    q
   a   BB        u
%s
%s
%s
""" % (G(20), G(20), G(20)))

C["spring_up"] = rows("""
          N o o
         ======



    S           a
%s
%s
%s
""" % (G(22), G(22), G(22)))

C["pit_double"] = rows("""
     o       o

   a      b
######  ####  ########
######  ####  ########
######  ####  ########
""")

C["moving_plat"] = rows("""
        o   o   o


#####  M          ######
#####             ######
#####             ######
""")

C["lift"] = rows("""
              N
            =====



      V
%s
%s
%s
""" % (G(20), G(20), G(20)))

C["pillars"] = rows("""
        o     T

      ##    ##    ##
      ##    ##    ##
####  ##    ##    ##  ##
####  ##    ##    ##  ##
####  ##    ##    ##  ##
""")

C["gauntlet"] = rows("""
    e     ?


   a   c    r    t
%s
%s
%s
""" % (G(22), G(22), G(22)))

C["flyers"] = rows("""
    o   o   o   o


   f       F     f
%s
%s
%s
""" % (G(22), G(22), G(22)))

C["spike_hop"] = rows("""
       o      o


     ====   ====   ==
    ^^^^^^^^^^^^^^^^
%s
%s
%s
""" % (G(24), G(24), G(24)))

C["climb"] = rows("""
               N
             ######
       ===   ######
             ######
   ===       ######   t
%s
%s
%s
""" % (G(24), G(24), G(24)))

C["coin_run"] = rows("""
   ooo   oTo   ooo   ooo
            w
      f        F
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["key_gate"] = rows("""
      k
     ===          ###
                  ###
   a              L    U
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["boost"] = rows("""
     ?   ?


        U     a
%s
%s
%s
""" % (G(18), G(18), G(18)))

# ---- the hidden Star -------------------------------------------------------
C["star_a"] = rows("""
           Z
          ===

      ===     ===

   ===           ===

%s
%s
%s
""" % (G(24), G(24), G(24)))

C["star_b"] = rows("""
########
#      #
#  Z   B      a
%s
%s
%s
""" % (G(22), G(22), G(22)))

C["star_c"] = rows("""
          =====

    a
######          ########
#####     Z     ########
########################
########################
""")

# ---- world specials --------------------------------------------------------
# Grassland: bounce mushrooms, rolling logs, prickly bushes
C["w1_shrooms"] = rows("""
      o o  o o  o o


       g    g    g
#####  #    #    #   #####
#####  #    #    #   #####
#####  #    #    #   #####
""")

C["w1_logs"] = rows("""
     o o o     o o o

   y          y        b
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["w1_bushes"] = rows("""
              N
       ====     ====

   x    x   a    x    x
%s
%s
%s
""" % (G(26), G(26), G(26)))

# Orchard: falling apples, a beehive, moles, tree branches
C["w2_apples"] = rows("""
     g      g      g




   a           m
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["w2_hive"] = rows("""
            y

        ====    ====

    a                 r
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["w2_branches"] = rows("""
      o o   N    o o
     ====       =====

  ====              ====

        m        a
%s
%s
%s
""" % (G(26), G(26), G(26)))

# Candy Carnival: conveyors, a peppermint saw, dripping goo
C["w3_belts"] = rows("""
       o o        o o


######G       H       ######
######                ######
######                ######
""")

C["w3_saw"] = rows("""
     o        o        o

   y        y

        a         b
%s
%s
%s
""" % (G(28), G(28), G(28)))

C["w3_drips"] = rows("""
####################
  z     z     z


      a      c         N
%s
%s
%s
""" % (G(28), G(28), G(28)))

# Icy Pond: slick ice, icicles, a pond to freeze over
C["w4_ice"] = rows("""
        o o o

    b            a
####iiiiiiii  iiiiiiii####
####iiiiiiii  iiiiiiii####
##########################
""")

C["w4_icicles"] = rows("""
##########################
   z    z    z    z


     a        r
%s
%s
%s
""" % (G(26), G(26), G(26)))

C["w4_pond"] = rows("""
              N


   R                    a
######~~~~~~~~~~~~~~~~######
######~~~~~~~~~~~~~~~~######
############################
""")

# Windy Mill: gusts, plank bridges, prickles
C["w5_gust"] = rows("""
          o  o  o



######g           ########
######            ########
######            ########
""")

C["w5_bridges"] = rows("""
        o o      o o

     =====    =====    ====


####                      ####
####                      ####
####                      ####
""")

C["w5_updraft"] = rows("""
                N
              =====




    a    x          x
%s
%s
%s
""" % (G(26), G(26), G(26)))

# Castle Feast: a drawbridge, swinging maces, torches
C["w6_bridge"] = rows("""


   J      A
##########      ################
##########      ################
##########      ################
""")

C["w6_maces"] = rows("""
############################
    y        y        y



        t          c
%s
%s
%s
""" % (G(28), G(28), G(28)))

C["w6_torches"] = rows("""
               N
              ####
        ####  ####
   z    ####z ####   z
%s
%s
%s
""" % (G(28), G(28), G(28)))

C["cracked"] = rows("""
              ####
              ####
   R          K    j   a
%s
%s
%s
""" % (G(26), G(26), G(26)))

# ---- boss arena ------------------------------------------------------------
C["arena"] = rows("""
     ===                ===

 @  1   P           X    E
%s
%s
%s
""" % (G(30), G(30), G(30)))


# --------------------------------------------------------------------------
# Worlds: what the chunk letters mean in each one.
# --------------------------------------------------------------------------
WORLDS = {
    1: {"theme": "grassland", "a": "slime_blob", "b": "mushroom_hopper", "c": "hedgehog_roller", "t": "hedgehog_roller",
        "f": "bee_buzzer", "F": "bee_buzzer", "r": "mushroom_hopper", "P": "FIRE_PEPPER", "Q": "BUBBLEBERRY", "R": "FIRE_PEPPER",
        "charm": "flower", "boss": "mega_mushroot",
        "extra": ["g = shroom", "y = roller dx=4 t=3", "m = slime_blob"]},
    2: {"theme": "orchard", "a": "apple_chomper", "b": "mushroom_hopper", "c": "crab_snipper", "t": "turtle_tank",
        "f": "crow_swooper", "F": "bee_buzzer", "r": "carrot_archer", "P": "WATERMELON", "Q": "HONEYCOMB", "R": "FIRE_PEPPER",
        "charm": "leaf", "boss": "gigantapple",
        "extra": ["g = faller every=3", "y = hive", "m = mole_digger"]},
    3: {"theme": "candy", "a": "shock_slime", "b": "candy_imp", "c": "crab_snipper", "t": "turtle_tank",
        "f": "pie_bat", "F": "balloon_jelly", "r": "candy_imp", "P": "POPCORN", "Q": "NOODLE", "R": "WATERMELON",
        "charm": "candy", "boss": "candy_king",
        "extra": ["G = conveyor w=4 dir=1", "H = conveyor w=4 dir=-1", "y = saw dx=4 t=2.6", "z = drip every=2.2", "m = slime_blob"]},
    4: {"theme": "icy", "a": "ice_slime", "b": "ice_puffin", "c": "hedgehog_roller", "t": "turtle_tank",
        "f": "ghost_poof", "F": "pie_bat", "r": "ice_puffin", "P": "FROSTBERRY", "Q": "COCOA_SHIELD", "R": "FROSTBERRY",
        "charm": "crystal", "boss": "frost_puffin_lord",
        "extra": ["z = icicle", "m = ice_slime"]},
    5: {"theme": "windy", "a": "fire_slime", "b": "pepper_goblin", "c": "crab_snipper", "t": "onion_knight",
        "f": "crow_swooper", "F": "balloon_jelly", "r": "carrot_archer", "P": "GARLIC_DASH", "Q": "THUNDER_CORN", "R": "BUBBLEBERRY",
        "charm": "leaf", "boss": "sky_airship_turtle",
        "extra": ["g = wind w=12 h=6 dir=1 power=0.9", "m = mole_digger", "K = cracked h=2"]},
    6: {"theme": "castle", "a": "shock_slime", "b": "pepper_goblin", "c": "onion_knight", "t": "rock_golem",
        "f": "ghost_poof", "F": "pie_bat", "r": "carrot_archer", "P": "LEMON_BEAM", "Q": "TOMATO_BOMB", "R": "GARLIC_DASH",
        "charm": "moon", "boss": "chef_castle_golem",
        "extra": ["J = button opens=b1 mode=once", "A = bridge id=b1 w=6", "y = mace r=2 t=3.2", "z = torch every=2.4",
                  "K = cracked h=2", "m = slime_blob"]},
}

FRUITS = ["cherry", "grape", "banana", "corn"]
# boosts are dealt out two per stage so that all of them appear in the campaign
BOOSTS = ["mushroom", "feather", "wings", "magnet", "clover", "orb", "time", "egg", "rainbow_star", "gem", "sun", "moon", "flower", "candy", "crystal", "leaf"]

STAGE_NAMES = {}

# stage id -> (chunk list, tips, hints)
STAGES = {
    # ------------------------------ World 1: Grassland
    "W1-L1": (["start", "flat_coins", "qblocks", "steps", "bowl_p", "cp", "pit_small", "tower", "hill", "w1_shrooms", "cp", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("move", "honk"), "Jump on the slimes or honk at them. | The first food bowl gives you Fire Shot. | Smash the crate by the little stone room to find the Star."),
    "W1-L2": (["start", "qblocks", "w1_shrooms", "bowl_q", "cp", "pit_plat", "spring_up", "w1_logs", "water", "cp", "tower", "w1_bushes", "cp", "star_a", "pit_small", "end"],
              ("flap", "spring"), "Bounce on the mushrooms to cross the gap. | Hold jump on a spring to go really high. | The Star floats above the highest platforms."),
    "W1-L3": (["start", "bowl_p", "w1_logs", "pit_double", "cp", "w1_bushes", "crate_wall", "moving_plat", "lift", "cp", "gauntlet", "climb", "cp", "star_c", "w1_shrooms", "end"],
              ("stomp", "notes"), "Hedgehogs are too prickly to jump on: use an attack. | Ride the moving platform across the big gap. | Look down in the dip for the Star."),
    "W1-X": (["start", "bowl_r", "coin_run", "boost", "w1_shrooms", "coin_run", "cp", "flyers", "high_road", "spring_up", "tower", "cp", "star_a", "coin_run", "end"],
             ("qblock", "hearts"), "This stage is all about coins. | 100 coins refill Tato's hearts. | Bees dip down at you: bop them from below."),
    "W1-B": (["arena"], ("boss", "power"), "Wait for the warning flash, then dodge. | Jump over the little shock waves. | Attack while Mega Mushroot is resting."),
    # ------------------------------ World 2: Orchard
    "W2-L1": (["start", "bowl_p", "w2_apples", "qblocks", "pit_small", "cp", "w2_branches", "steps", "water", "cp", "w2_hive", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("apples", "power"), "Apples wobble before they fall. | Watermelon throws three slices at once. | Smash the crate by the stone room for the Star."),
    "W2-L2": (["start", "bowl_q", "w2_apples", "tunnel", "cp", "pit_double", "w2_hive", "crate_wall", "spring_up", "cp", "w2_branches", "gauntlet", "cp", "star_a", "hill", "end"],
              ("swap", "stomp"), "Moles only pop up when you are near: hit them then. | Honey glues a creature to the spot. | A new bowl swaps your power with a Flavor Burst."),
    "W2-L3": (["start", "bowl_p", "w2_branches", "pillars", "cp", "w2_apples", "moving_plat", "climb", "lift", "cp", "w2_hive", "key_gate", "cp", "star_c", "pit_plat", "end"],
              ("key", "notes"), "Find the key on the little platform, then walk into the lock. | Turtles hide in their shells after a hit. | Check the dip for the Star."),
    "W2-X": (["start", "bowl_r", "boost", "flyers", "coin_run", "w2_hive", "cp", "flyers", "pillars", "coin_run", "w2_branches", "cp", "star_a", "flyers", "end"],
             ("flap", "hearts"), "A whole stage of things that fly. | Popcorn-style arcs are great here, but any power works. | Keep moving!"),
    "W2-B": (["arena"], ("boss", "power"), "Gigantapple charges straight across: jump it. | Seeds come in threes. | Attack while it catches its breath."),
    # ------------------------------ World 3: Candy Carnival
    "W3-L1": (["start", "bowl_p", "w3_belts", "qblocks", "cp", "w3_saw", "pit_plat", "tower", "cp", "w3_drips", "steps", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("conveyor", "power"), "Candy belts carry you along. | Popcorn pops up and over: good for things above. | Watch the pink goo dripping from the ceiling."),
    "W3-L2": (["start", "bowl_q", "w3_belts", "w3_saw", "cp", "crate_wall", "w3_belts", "spring_up", "moving_plat", "cp", "w3_drips", "gauntlet", "cp", "star_a", "pit_small", "end"],
              ("swap", "notes"), "The Noodle Whip reaches a long way and grabs coins. | Jump when the peppermint slides away. | The Star is up high."),
    "W3-L3": (["start", "bowl_p", "lift", "w3_saw", "pillars", "cp", "w3_belts", "climb", "w3_drips", "cp", "spike_hop", "key_gate", "cp", "star_c", "w3_belts", "end"],
              ("key", "drop"), "A long climb. Flap to make the far jumps. | Shock Slimes zap now and then: keep your distance. | Look in the dip for the Star."),
    "W3-X": (["start", "bowl_r", "boost", "flyers", "w3_belts", "coin_run", "cp", "flyers", "spring_up", "coin_run", "w3_saw", "cp", "star_a", "flyers", "end"],
             ("flap", "hearts"), "Pop the Balloon Jellies' balloons and they fall. | Lots of coins up in the air. | Keep bouncing!"),
    "W3-B": (["arena"], ("boss", "power"), "Candy rains from above: keep moving. | Jump the sugar waves. | Attack while the King rests."),
    # ------------------------------ World 4: Icy Pond
    "W4-L1": (["start", "bowl_p", "w4_ice", "qblocks", "cp", "w4_pond", "steps", "w4_icicles", "cp", "pit_plat", "w4_ice", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("ice", "power"), "Ice is slippery: slow down before a ledge. | Freeze Shot turns a creature into a block you can stand on. | It also freezes the pond."),
    "W4-L2": (["start", "bowl_q", "w4_icicles", "tunnel", "cp", "w4_ice", "crate_wall", "w4_pond", "spring_up", "cp", "w4_icicles", "gauntlet", "cp", "star_a", "hill", "end"],
              ("swap", "slide"), "Icicles wobble, then drop. | The Cocoa Shield bounces snowballs back. | Ghosts only move when you look away."),
    "W4-L3": (["start", "bowl_p", "w4_ice", "pillars", "cp", "w4_icicles", "moving_plat", "climb", "w4_pond", "cp", "lift", "key_gate", "cp", "star_c", "w4_ice", "end"],
              ("key", "swim"), "A slippery climb. | Freeze the pond and walk across. | The Star is in the dip."),
    "W4-X": (["start", "bowl_r", "boost", "w4_ice", "coin_run", "w4_ice", "cp", "flyers", "w4_pond", "coin_run", "w4_icicles", "cp", "star_a", "w4_ice", "end"],
             ("slide", "hearts"), "Hold down while running to belly-slide across the ice. | Lots of coins. | Whee!"),
    "W4-B": (["arena"], ("boss", "power"), "Jump over the Ice Beam. | A red mark shows where spikes will pop up. | Attack while the Puffin Lord rests."),
    # ------------------------------ World 5: Windy Mill
    "W5-L1": (["start", "bowl_p", "w5_gust", "qblocks", "cp", "w5_bridges", "steps", "w5_updraft", "cp", "pit_double", "w5_gust", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("wind", "power"), "Gusts carry Tato over the gap: jump in and glide. | Garlic Dash zooms through creatures. | Fire Slimes are too hot to jump on."),
    "W5-L2": (["start", "bowl_q", "w5_bridges", "tunnel", "cp", "w5_gust", "crate_wall", "moving_plat", "spring_up", "cp", "w5_updraft", "gauntlet", "cp", "star_a", "hill", "end"],
              ("swap", "flap"), "Thunder Corn's bolt jumps between creatures. | Onion Knights block shots from the front. | Hit them from behind or jump on them."),
    "W5-L3": (["start", "bowl_p", "w5_gust", "pillars", "cp", "w5_bridges", "lift", "climb", "cracked", "cp", "w5_gust", "key_gate", "cp", "star_c", "w5_bridges", "end"],
              ("key", "notes"), "Cracked walls break with a Garlic Dash. | Flap across the plank bridges. | The Star is in the dip."),
    "W5-X": (["start", "bowl_r", "boost", "w5_gust", "coin_run", "w5_bridges", "cp", "flyers", "w5_gust", "coin_run", "w5_updraft", "cp", "star_a", "w5_gust", "end"],
             ("wind", "hearts"), "Ride the wind from one end to the other. | Glide with jump held. | Coins everywhere!"),
    "W5-B": (["arena"], ("boss", "power"), "The Turtle hovers: jump or shoot upward. | Its propeller pushes you: run against the wind. | Attack when it dips down to rest."),
    # ------------------------------ World 6: Castle Feast
    "W6-L1": (["start", "bowl_p", "w6_torches", "qblocks", "cp", "w6_bridge", "steps", "w6_maces", "cp", "pit_plat", "w6_torches", "high_road", "cp", "star_b", "flat_coins", "end"],
              ("bridge", "power"), "Step on the button to lower the drawbridge. | Lemon Beam goes through everything in a line. | Torches flare on a rhythm."),
    "W6-L2": (["start", "bowl_q", "w6_maces", "tunnel", "cp", "cracked", "w6_bridge", "crate_wall", "spring_up", "cp", "w6_torches", "gauntlet", "cp", "star_a", "hill", "end"],
              ("swap", "button"), "Tomato Bomb breaks cracked walls. | Walk under a mace as it swings away. | Rock Golems take a lot of hits."),
    "W6-L3": (["start", "bowl_p", "w6_maces", "pillars", "cp", "w6_bridge", "moving_plat", "climb", "w6_torches", "cp", "lift", "key_gate", "cp", "star_c", "w6_maces", "end"],
              ("key", "notes"), "The longest climb in the castle. | Use what you have learned. | The Star is in the dip."),
    "W6-X": (["start", "bowl_r", "boost", "gauntlet", "w6_maces", "coin_run", "cp", "flyers", "cracked", "w6_torches", "spike_hop", "cp", "star_a", "gauntlet", "end"],
             ("hearts", "power"), "A bit of everything. | Take it one room at a time. | You can do it!"),
    "W6-B": (["arena"], ("boss", "power"), "Food Bombs splat in a ring: step away. | Jump the cake waves. | Helpers march in halfway: bop them first."),
}


def stitch(names):
    """Glue chunks left to right on a 15-row grid."""
    grid = [""] * ROWS
    for name in names:
        chunk = C[name]
        width = len(chunk[0])
        pad = ROWS - len(chunk)
        assert pad >= 0, name
        for r in range(ROWS):
            grid[r] += (" " * width) if r < pad else chunk[r - pad]
    return grid


def place_notes(grid, stage_id):
    """Exactly three Treasure Notes, spread across the stage. Chunks mark
    good hiding places with N; spare marks become coins. A stage with fewer
    than three marks gets the missing notes floating three tiles above open
    ground (a jump and a flap away)."""
    width = len(grid[0])
    spots = [(r, c) for r in range(ROWS) for c in range(width) if grid[r][c] == "N"]
    spots.sort(key=lambda s: s[1])
    if len(spots) >= 3:
        n = len(spots)
        keep = [spots[0], spots[n // 2], spots[-1]]
    else:
        keep = list(spots)
        for frac in (0.2, 0.5, 0.8, 0.35, 0.65):
            if len(keep) >= 3:
                break
            c0 = int(width * frac)
            for c in list(range(c0, min(c0 + 12, width - 2))) + list(range(c0, max(c0 - 12, 2), -1)):
                open_air = all(grid[r][c] == " " for r in range(7, 12)) and grid[12][c] == GROUND
                far = all(abs(c - kc) > 14 for (_kr, kc) in keep)
                if open_air and far:
                    keep.append((9, c))
                    break
    keepset = set(keep)
    out = []
    for r in range(ROWS):
        line = list(grid[r])
        for c, ch in enumerate(line):
            if (r, c) in keepset:
                line[c] = "n"
            elif ch == "N":
                line[c] = "o"
        out.append("".join(line))
    assert len(keepset) == 3 or stage_id.endswith("-B"), "%s has %d note spots" % (stage_id, len(keepset))
    return out


def build(stage_id, spec, index):
    names, tips, hints = spec
    world = int(stage_id[1])
    w = WORLDS[world]
    grid = stitch(names)
    boss = stage_id.endswith("-B")
    if not boss:
        grid = place_notes(grid, stage_id)
    grid = [g.replace("Z", "*") for g in grid]
    if w["theme"] == "grassland":
        # Grassland's row on the world board has no treat of its own
        grid = [g.replace("T", "o") for g in grid]
    if boss:
        # three notes on the arena's ledges
        for (r, c) in ((ROWS - 6, 6), (ROWS - 6, 14), (ROWS - 6, 26)):
            line = list(grid[r])
            line[c] = "n"
            grid[r] = "".join(line)
    boost_a = BOOSTS[(index * 2) % len(BOOSTS)]
    boost_b = BOOSTS[(index * 2 + 1) % len(BOOSTS)]
    fruit = FRUITS[index % len(FRUITS)]
    legend = [
        "a = %s" % w["a"], "b = %s" % w["b"], "c = %s" % w["c"], "t = %s" % w["t"],
        "f = %s up=1.5 range=3" % w["f"], "F = %s up=3 range=4" % w["F"], "r = %s" % w["r"],
        "P = power %s" % w["P"], "Q = power %s" % w["Q"], "R = power %s" % w["R"],
        "p = pickup %s" % w["charm"], "q = pickup %s" % fruit, "j = pickup gem",
        "u = pickup %s" % boost_a, "U = pickup %s" % boost_b,
        "w = pickup wings", "e = pickup rainbow_star", "T = pickup treat",
        "D = decor", "x = spiky",
        "M = platform w=2 dx=9 dy=0 t=3 thin", "V = platform w=2 dx=0 dy=-5 t=2.6 thin",
        "1 = sign text=%s" % tips[0], "2 = sign text=%s" % tips[1],
    ] + w["extra"]
    if boss:
        legend.append("X = boss %s" % w["boss"])
        legend.append("E = goal needs=boss")
    used = set("".join(grid))
    legend = [l for l in legend if l[0] in used]
    text = "; Built by tools/build_levels.py from chunks: %s\n" % " ".join(names)
    text += "[meta]\nid = %s\nworld = %d\ntheme = %s\nkind = %s\nhints = %s\n" % (
        stage_id, world, w["theme"], "boss" if boss else ("optional" if stage_id.endswith("-X") else "core"), hints)
    text += "[legend]\n" + "\n".join(legend) + "\n[map]\n" + "\n".join(g.rstrip() or " " for g in grid) + "\n"
    return text, set(l.split("=")[1].strip() for l in legend)


HUB = """; The Home Nest: world gates, the notebook, the wardrobe and the trial room.
[meta]
id = HUB
name = Home Nest
kind = hub
theme = nest
music = hub
hints = Each picture is a world: walk up and press up. | The notebook remembers what you have found. | Coins buy things to wear at the wardrobe.
[legend]
1 = sign text=hub_gate
2 = sign text=hub_book
3 = sign text=hub_trial
4 = sign text=hub_wardrobe
a = worldgate W1
b = worldgate W2
c = worldgate W3
d = worldgate W4
e = worldgate W5
f = worldgate W6
K = book
W = wardrobe
T = door to=TRIAL
D = decor
[map]











  D  2 K   4 W    @   1   a     b     c     d     e     f    3  T   D
########################################################################
########################################################################
########################################################################
"""

TRIAL = """; Snack Trial Room: every power in a row, with a few creatures to try them on.
[meta]
id = TRIAL
name = Snack Trial Room
kind = hub
theme = nest
music = hub
hints = Touch a bowl to swap powers. | Each swap sets off a Flavor Burst. | Leave through the flag on the left.
[legend]
A = power FIRE_PEPPER
B = power BUBBLEBERRY
c = power WATERMELON
d = power HONEYCOMB
e = power POPCORN
f = power NOODLE
g = power FROSTBERRY
i = power COCOA_SHIELD
j = power GARLIC_DASH
l = power THUNDER_CORN
m = power LEMON_BEAM
q = power TOMATO_BOMB
s = slime_blob
t = turtle_tank
y = bee_buzzer up=2 range=3
T = door to=HUB
X = crate
[map]









                  ====              ====              ====

 T  @    A  B  c  d   s   X  e  f  g  i   t   X  j  l  m  q   y   s   X
##########################################################################
##########################################################################
##########################################################################
"""

TEST = """; Movement and systems test room (not part of the campaign).
[meta]
id = TEST
name = Test Kitchen
kind = test
theme = grassland
[legend]
1 = sign text=move
P = power FIRE_PEPPER
Q = power FROSTBERRY
a = slime_blob
b = mushroom_hopper
f = bee_buzzer up=2 range=3
M = platform w=2 dx=3 dy=0 t=2.5 thin
u = pickup wings
[map]







                                                  n
                       ?%?        o o o          ===
                                             ====
 @  1   P    a    B        b    Q    f    S          M        k   L   *   C    E
####################################################     #######################
####################################################     #######################
####################################################     #######################
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    pickups_used = set()
    creatures = set()
    for index, (stage_id, spec) in enumerate(STAGES.items()):
        for name in spec[0]:
            assert name in C, "%s: unknown chunk %s" % (stage_id, name)
        text, things = build(stage_id, spec, index)
        with open(os.path.join(OUT, stage_id + ".txt"), "w") as f:
            f.write(text)
        for t in things:
            parts = t.split()
            if parts[0] == "pickup":
                pickups_used.add(parts[1])
            else:
                creatures.add(parts[0])
        print("%-6s %3d columns, %2d chunks" % (stage_id, len(text.split("[map]\n")[1].split("\n")[12]), len(spec[0])))
    for name, text in (("HUB", HUB), ("TRIAL", TRIAL), ("TEST", TEST)):
        with open(os.path.join(OUT, name + ".txt"), "w") as f:
            f.write(text)
    all_pickups = {"gem", "orb", "flower", "clover", "feather", "leaf", "candy", "crystal", "rainbow_star", "moon",
                   "sun", "cherry", "grape", "banana", "corn", "mushroom", "egg", "time", "magnet", "wings"}
    missing = all_pickups - pickups_used
    print("level pickups used: %d of 20%s" % (len(all_pickups & pickups_used), ("  MISSING: %s" % sorted(missing)) if missing else ""))
    all_creatures = {"mushroom_hopper", "slime_blob", "apple_chomper", "bee_buzzer", "hedgehog_roller", "turtle_tank", "crow_swooper",
                     "ghost_poof", "crab_snipper", "mole_digger", "onion_knight", "carrot_archer", "pie_bat", "ice_puffin",
                     "candy_imp", "pepper_goblin", "rock_golem", "balloon_jelly", "fire_slime", "ice_slime", "shock_slime"}
    missing_c = all_creatures - creatures
    print("creatures used: %d of 21%s" % (len(all_creatures & creatures), ("  MISSING: %s" % sorted(missing_c)) if missing_c else ""))


if __name__ == "__main__":
    main()
    # Preserve the v0.4 play routes whenever the base campaign is regenerated.
    import runpy
    runpy.run_path(os.path.join(ROOT, "tools", "enrich_levels.py"), run_name="__main__")
