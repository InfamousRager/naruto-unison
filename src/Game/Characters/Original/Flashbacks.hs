{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_HADDOCK hide #-}

module Game.Characters.Original.Flashbacks (flashbackCs) where

import StandardLibrary
import Game.Functions
import Game.Game
import Game.Structure

flashbackCs :: [Group -> Character]
flashbackCs =
  [ Character
    "Konohamaru Sarutobi"
    "The overly bold grandson of the third Hokage, Konohamaru has a knack for getting into trouble and requiring others to bail him out. His usefulness in battle depends on how willing his teammates are to babysit him."
    [ [ newSkill
        { label   = "Refocus"
        , desc    = "Konohamaru tries his best to concentrate on the fight. For 3 turns, effects from his allies on him are twice as powerful. While active, this skill becomes [Unsexy Technique][n]."
        , classes = [Mental]
        , cost    = χ [Rand]
        , cd      = 4
        , effects = [(Self, vary' 3 "Refocus" "Unsexy Technique" • tag 3
                          • alliedTeam . self § hide 3 [Boost 2])]
        }
      , newSkill 
        { label   = "Unsexy Technique"
        , desc    = "Konohamaru distracts an enemy with his modified version of the transformation technique he learned from Naruto. For 1 turn, the target is immune to effects from their allies and cannot reduce damage, become invulnerable, counter, or reflect."
        , classes = [Chakra]
        , cost    = χ [Nin]
        , cd      = 1
        , effects = [(Enemy, apply 1 [Seal, Expose, Uncounter ])]
        }
      ]
    , [ newSkill
        { label   = "Throw a Fit"
        , desc    = "Konohamaru freaks out and punches wildly at an enemy, dealing 10 damage to them for 3 turns. Deals 5 additional damage per skill affecting Konohamaru from his allies."
        , classes = [Physical, Melee]
        , cost    = χ [Rand]
        , cd      = 3
        , channel = Action 3
        , effects = [(Enemy, perHelpful 5 damage 10)]
        }
      ]
    , [ newSkill
        { label   = "Throw a Shuriken"
        , desc    = "Konohamaru flings a shuriken almost too big for his hands at an enemy, dealing 10 damage and 10 additional damage per skill affecting Konohamaru from his allies."
        , classes = [Physical, Ranged]
        , cost    = χ [Tai]
        , effects = [(Enemy, perHelpful 10 damage 10)]
        }
      ]
    , invuln "Hide?" "Konohamaru" [Mental]
    ] []
  , Character 
    "Hiashi Hyūga"
    "A jōnin from the Hidden Leaf Village and father to Hinata and Hanabi, Hiashi does not tolerate weakness or failure. All of the Hyūga clan's secret techniques have been passed down to him, and he wields them with unmatched expertise."
    [ [ newSkill
        { label   = "Gentle Fist"
        , desc    = "Hiashi slams an enemy, dealing 20 damage and removing 1 random chakra. Next turn, he repeats the attack on a random enemy."
        , classes = [Physical, Melee]
        , cost    = χ [Tai, Rand]
        , cd      = 2
        , start   = [ (Self, flag) 
                    , (Enemy, drain 1 • damage 20)
                    ]
        , effects = [(REnemy, ifnotI "Gentle Fist" 
                            § damage 20 ° drain 1)]
        }
      ]
    , [ newSkill
        { label   = "Eight Trigrams Palm Rotation"
        , desc    = "Hiashi spins toward an enemy, becoming invulnerable for 2 turns and dealing 15 damage to the target and 10 to all other enemies each turn."
        , classes = [Chakra, Melee]
        , cost    = χ [Blood, Rand]
        , cd      = 3
        , channel = Action 2
        , start   = [ (Self,     apply 1 [Invulnerable All]) 
                    , (Enemy,    damage 15)
                    , (XEnemies, damage 10)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Eight Trigrams Air Palm Wall"
        , desc    = "Hiashi prepares to blast an enemy's attack back. The first harmful skill used on him or his allies next turn will be reflected."
        , classes = [Chakra, Melee]
        , cost    = χ [Blood]
        , cd      = 3
        , effects = [(Enemies, trap (-1) OnReflectAll . everyone 
                             § removeTrap "Eight Trigrams Air Palm Wall")]
        }
      ]
    , invuln "Byakugan Foresight" "Hiashi" [Mental]
    ] []
  , Character
    "Chōza Akimichi"
    "A jōnin from the Hidden Leaf Village and Chōji's father, Chōza instills confidence in his comrades with his bravery and wisdom. Never one to back down from a fight, he defends his allies and forces the attention of his enemies to himself."
    [ [ newSkill
        { label   = "Chain Bind"
        , desc    = "Chōza slows an enemy, dealing 5 damage and weakening their physical and chakra damage by 10 for 1 turn. Chōza's team gains 5 permanent destructible defense."
        , classes = [Physical, Melee]
        , cost    = χ [Rand]
        , effects = [ (Enemy,  damage 5
                             • apply 1 
                               [Weaken Physical Flat 10, Weaken Chakra Flat 10])
                    , (Allies, defend 0 5)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Human Boulder"
        , desc    = "Chōza transforms into a rolling juggernaut. For 3 turns, he deals 15 damage to an enemy and provides 10 destructible defense to himself and his allies for 1 turn. Each turn, if the target is affected by [Chain Bind], it lasts 1 additional turn on them."
        , classes = [Physical, Melee]
        , cost    = χ [Blood, Rand]
        , cd      = 3
        , channel = Action 3
        , effects = [ (Allies, defend 1 10)
                    , (Enemy,  damage 15
                             • ifU "Chain Bind" 
                               § apply' "Chain Bind" 1 
                                 [ Weaken Physical Flat 10
                                 , Weaken Chakra Flat 10
                                 ])
                    ]
        }
      ] 
    , [ newSkill
        { label   = "Partial Expansion"
        , desc    = "If used on an enemy, the next harmful non-mental skill they use will be countered. If used on an ally, the next harmful non-mental skill used on them wil be countered. The person countered will receive 10 damage, bypassing invulnerability."
        , classes = [Physical, Melee, Single, Invisible, Unreflectable]
        , cost    = χ [Blood]
        , cd      = 2
        , effects = [ (XAlly, apply 0 [Parry NonMental $ damage 10])
                    , (Enemy, trap 0 (OnCounter NonMental) § damage 10)
                    ]
        }
      ]
    , invuln "Block" "Chōza" [Physical]
    ] []
  , Character
    "Inoichi Yamanaka"
    "A jōnin from the Hidden Leaf Village and Ino's father, Inoichi can solve practically any dilemma with his analytical perspective. Under his watchful gaze, every move made by his enemies only adds to his strength."
    [ [ newSkill
        { label   = "Psycho Mind Transmission"
        , desc    = "Inoichi invades the mind of an enemy, dealing 20 damage to them for 2 turns. While active, the target cannot use counter or reflect skills."
        , classes = [Mental, Melee, Uncounterable, Unreflectable]
        , cost    = χ [Nin]
        , cd      = 1
        , channel = Control 2
        , effects = [(Enemy, damage 20 • apply 1 [Uncounter])]
        }
      ]
    , [ newSkill
        { label   = "Sensory Radar"
        , desc    = "Inoichi steps back and focuses on the tide of battle. Each time an enemy uses a harmful skill, Inoichi will recover 10 health and gain a stack of [Sensory Radar]. While active, this skill becomes [Sensory Radar: Collate][r]."
        , classes = [Mental, Ranged]
        , cost    = χ [Nin]
        , effects = [ (Self, vary "Sensory Radar" "Sensory Radar: Collate")
                    , (Enemies, trap 0 OnHarm . self § heal 10 ° addStack)
                    ]
        }
      , newSkill
        { label   = "Sensory Radar: Collate"
        , desc    = "Inoichi compiles all the information he has gathered and puts it to use. For every stack of [Sensory Radar], he gains a random chakra. Ends [Sensory Radar]."
        , classes = [Mental, Ranged]
        , cost    = χ [Rand]
        , effects = [ (Enemies, removeTrap "Sensory Radar")
                    , (Self,    vary "Sensory Radar" ""
                              • perI "Sensory Radar" 0 
                                (gain . flip replicate Rand) 1
                              • remove "Sensory Radar")
                    ]
        }
      ]
    , [ newSkill
        { label   = "Mental Invasion"
        , desc    = "Inoichi preys on an enemy's weaknesses. For 4 turns, all invulnerability skills used by the target will have their duration reduced by 1 turn. While active, anyone who uses a harmful mental skill on the target will become invulnerable for 1 turn."
        , classes = [Mental, Ranged]
        , cost    = χ [Rand]
        , cd      = 4
        , effects = [(Enemy, apply 4 [Throttle Invulnerable 1]
                           • trapFrom 4 (OnHarmed Mental) 
                             § apply 1 [Invulnerable All])]
        }
      ]
    , invuln "Mobile Barrier" "Inoichi" [Chakra]
    ] []
  , Character
    "Kushina Uzumaki"
    "Known as the Red-Hot Habanero for her fiery hair and fierce temper, Naruto's mother possesses exceptional chakra necessary to become the nine-tailed fox's jinchūriki. Kushina specializes in unique sealing techniques that bind and incapacitate her enemies."
    [ [ newSkill
        { label   = "Double Tetragram Seal"
        , desc    = "Kushina seals away an enemy's power, dealing 15 piercing damage, stunning them for 1 turn, removing 1 chakra, and permanently weakening their damage by 5."
        , classes = [Chakra, Ranged]
        , cost    = χ [Gen, Rand]
        , cd      = 1
        , effects = [(Enemy, drain 1 • damage 15
                            • apply 1 [Stun All] 
                            • apply 0 [Weaken All Flat 5])]
        }
      ]
    , [ newSkill
        { label   = "Life Link"
        , desc    = "Kushina binds her life-force to that of an enemy. For 4 turns, if either dies, the other will die as well. Effect cannot be avoided, prevented, or removed."
        , classes = [Mental, Ranged, Bypassing, Unremovable, Uncounterable, Unreflectable, Direct]
        , cost    = χ [Gen, Rand]
        , cd      = 5
        , effects = [(Enemy, tag 4 • trap 4 OnDeath § self kill
                           • self . trap 4 OnDeath . everyone 
                             § ifU "Life Link" kill')]
        }
      ]
    , [ newSkill
        { label   = "Adamantine Sealing Chains"
        , desc    = "A cage of chain-shaped chakra seals an enemy, removing the effects of helpful skills from them and stunning them for 2 turns. While active, the target is immune to effects from allies and invulnerable."
        , classes = [Chakra, Ranged, Bypassing, Uncounterable, Unreflectable]
        , cost    = χ [Blood, Gen]
        , cd      = 4
        , effects = [(Enemy, purge 
                           • apply 2 [Stun All, Invulnerable All, Seal])]
        }
      ]
    , invuln "Adamantine Covering Chains" "Kushina" [Chakra]
    ] []
  , Character
    "Minato Namikaze"
    "Known as the Yellow Flash for his incredible speed and mastery of space-time techniques, Naruto's father is a jōnin squad leader from the Hidden Leaf Village. Minato fights using unique kunai that allow him to teleport arround the battlefield."
    [ [ newSkill
        { label   = "Flying Raijen"
        , desc    = "Minato teleports to a target, becoming invulnerable for 1 turn. If he teleports to an enemy, he deals 30 damage. If he teleports to an ally, the ally becomes invulnerable for 1 turn."
        , classes = [Physical, Melee, Bypassing]
        , cost    = χ [Gen, Rand]
        , effects = [ (Self,    apply 1 [Invulnerable All])
                    , (XAlly,   apply 1 [Invulnerable All]
                              • ifI "Space-Time Marking" 
                                § tag' "Space-Time Marking" 1)
                    , (Enemy,   damage 30
                              • ifI "Space-Time Marking"
                                § tag' "Space-Time Marking" 1)
                    , (XAllies, ifU "Space-Time Marking" 
                                § apply 1 [Invulnerable All])
                    , (Enemies, ifU "Space-Time Marking" § damage 30)

                    ]
        }
      ]
    , [ newSkill
        { label   = "Sensory Technique"
        , desc    = "Minato's senses expand to cover the battlefield, preventing enemies from reducing damage or becoming invulnerable for 2 turns. Each turn, Minato gains a random chakra."
        , classes = [Chakra, Ranged]
        , cost    = χ [Nin]
        , cd      = 3
        , channel = Control 2
        , effects = [ (Enemies, apply 1 [Expose])
                    , (Self,    gain [Rand])
                    ]
        }
      ]
    , [ newSkill
        { label   = "Space-Time Marking"
        , desc    = "For 3 turns, [Flying Raijen] marks its target for 1 turn. Using [Flying Raijen] causes marked allies to become invulnerable for 1 turn and deals 30 damage to marked enemies, bypassing invulnerability."
        , classes = [Physical, Melee]
        , cost    = χ [Gen, Nin]
        , cd      = 6
        , effects = [(Self, tag 3)]
        }
      ]
    , invuln "Flying Light" "Minato" [Physical]
    ] []
  , Character
    "Yondaime Minato"
    "Now the fourth Hokage, Minato has been shaped by his responsibilities into a thoughtful and strategic leader. With his space-time jutsu, he redirects the attacks of his enemies and effortlessly passes through their defenses."
    [ [ newSkill
        { label   = "Space-Time Marking"
        , desc    = "Minato opportunistically marks targets to use as teleport destinations for avoiding attacks. Next turn, allies and enemies who do not use a skill will be marked by this skill for 4 turns. Minato gains 5 points of damage reduction for each marked target. This skill stacks."
        , classes = [Physical, Ranged, InvisibleTraps]
        , cost    = χ [Blood]
        , cd      = 1
        , effects = [ (XAllies, delay 0 . trap 1 OnNoAction
                                $ apply' "Space-Time Marking " 3 []
                                • self § hide 4 [Reduce All Flat 5])
                    , (Enemies, trap (-1) OnNoAction 
                                $ apply' "Space-Time Marking " (-4) []
                                • self § hide 4 [Reduce All Flat 5])
                    ]
        }
      ]
    , [ newSkill
        { label   = "Teleportation Barrier"
        , desc    = "Space warps around Minato or one of his allies. The first harmful skill used on the target next turn will be reflected."
        , classes = [Chakra, Ranged, Unreflectable]
        , cost    = χ [Gen]
        , cd      = 3
        , effects = [(Ally, apply 1 [Reflect])]
        }
      ]
    , [ newSkill
        { label   = "Rasengan"
        , desc    = "Minato teleports behind an enemy and slams an orb of chakra into them, dealing 20 damage. In quick succession, he teleports between all enemies affected by [Space-Time Marking], dealing 20 damage for every stack of [Space-Time Marking] on them."
        , classes = [Chakra, Melee, Bypassing]
        , cost    = χ [Blood, Rand]
        , effects = [ (Enemy, damage 20)
                    , (Enemies, perU "Space-Time Marking " 20 damage 0)
                    ]
        }
    ]
    , invuln' "Round-Robin Raijen" 
              "Minato and allies affected by [Space-Time Marking] become invulnerable for 1 turn." 
            [Chakra] 
            [alliedTeam . ifU "Space-Time Marking " 
                          § apply 1 [Invulnerable All]]
    ] []
  , let kannon = changeWith "Veritable 1000-Armed Kannon" $ \_ skill -> 
                 skill { channel = Action 3, cost = χ [Blood] }
    in Character
    "Hashirama Senju"
    "The founder and first Hokage of the Hidden Leaf Village, Hashirama is headstrong and enthusiastic. He believes with all his heart that communities should behave as families, taking care of each other and protecting their children from the cruelties of war. Due to a unique genetic mutation, Hashirama is able shape wood into defensive barriers and constructs."
    [ [ newSkill
        { label   = "Wooden Dragon"
        , desc    = "A vampiric dragon made of wood drains chakra from Hashirama's enemies, making him invulnerable to chakra skills for 2 turns. While active, Hashirama steals 1 random chakra from his enemies each turn."
        , classes = [Chakra, Melee]
        , cost    = χ [Blood, Rand]
        , cd      = 2
        , channel = Action 2
        , effects = [ (Self,   apply 1 [Invulnerable Chakra]) 
                    , (REnemy, steal 1)
                    ]
        , changes = kannon
        }
      ]
    , [ newSkill
        { label   = "Wood Golem"
        , desc    = "A giant humanoid statue attacks an enemy for 2 turns, dealing 20 damage each turn. While active, Hashirama is invulnerable to physical skills."
        , classes = [Physical, Melee]
        , cost    = χ [Blood, Rand]
        , cd      = 2
        , channel = Action 2
        , effects = [ (Enemy, damage 20) 
                    , (Self,  apply 1 [Invulnerable Physical])
                    ]
        , changes = kannon
        }
      ]
    , [ newSkill
        { label   = "Veritable 1000-Armed Kannon"
        , desc    = "A titanic many-handed Buddha statue looms over the battlefield, providing 30 permanent destructible defense to Hashirama and his allies. For the next 3 turns, [Wooden Dragon] and [Wood Golem] cost 1 fewer random chakra and last 1 additional turn."
        , classes = [Physical]
        , cost    = χ [Blood, Blood]
        , cd      = 2
        , effects = [ (Allies, defend 0 30)
                    , (Self,   tag 3)
                    ]
        }
      ]
    , invuln "Foresight" "Hashirama" [Mental]
    ] []
  , Character
    "Young Kakashi"
    "A member of Team Minato, Kakashi is the thirteen-year-old son of the legendary White Fang. His early ninjutsu and borrowed sharingan make him the equal of any adult he faces."
    [ [ newSkill
        { label   = "White Light Blade"
        , desc    = "Kakashi deals 20 piercing damage to an enemy with his sword. For 1 turn, the target's non-affliction damage is weakened by 5 and Kakashi's damage is increased by 5."
        , classes = [Physical, Melee]
        , cost    = χ [Tai]
        , effects = [ (Enemy, damage 20 • apply 1 [Weaken All Flat 5]
                            • ifI "Sharingan Stun" § apply 1 [Stun All])
                    , (Self,  apply 1 [Strengthen All Flat 5])
                    ]
        }
      ]
    , [ newSkill
        { label   = "Amateur Lightning Blade"
        , desc    = "Using an early form of his signature technique, Kakashi deals 20 piercing damage to one enemy. For 1 turn, the target's non-affliction damage is weakened by 5 and Kakashi's damage is increased by 5."
        , classes = [Chakra, Melee]
        , cost    = χ [Nin]
        , effects = [ (Enemy, damage 20 • apply 1 [Weaken All Flat 5]
                            • ifI "Sharingan Stun" § apply 1 [Stun All])
                    , (Self,  apply 1 [Strengthen All Flat 5])
                    ]
        }
      ]
    , [ newSkill
        { label   = "Sharingan"
        , desc    = "Kakashi anticipates an opponent's moves for 2 turns. If they use a skill that removes or steals chakra, Kakashi gains a random chakra. If they use a skill that stuns, Kakashi's skills will stun next turn. If they use a skill that damages, Kakashi's damage will be increased by 10 during the next turn."
        , classes = [Mental, Ranged, InvisibleTraps]
        , cd      = 1
        , effects = [(Enemy, trap 1 OnChakra . self § gain [Rand]
                           • trap 1 OnStun   . self § gain [Rand]
                           • trap 1 OnDamage . self 
                             § apply 1 [Strengthen All Flat 10])]
        }
      ]
    , invuln "Parry" "Kakashi" [Physical]
    ] []
  , Character
      "Rin Nohara"
      "A chūnin on Team Minato, Rin is a quiet but strong-willed medical-nin. Her priority is always healing her teammates, though she can also defend herself with traps if necessary."
      [ [ newSkill
        { label   = "Pit Trap"
        , desc    = "An enemy falls into a pit and is trapped there for 1 turn. At the end of their turn, the target takes 15 piercing damage. If they used a skill that turn, they take 15 additional damage. While active, Rin gains 15 points of damage reduction."
        , classes = [Invisible, Bypassing]
        , cost    = χ [Gen]
        , effects = [(Self,  apply 1 [Reduce All Flat 15])
                    , (Enemy, trap (-1) (OnAction All) flag
                            • delay (-1) § withU "Pit Trap" 15 pierce 15)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Mystical Palm Healing"
        , desc    = "Rin restores 25 health to herself or an ally and cures the target of enemy effects."
        , classes = [Chakra]
        , cost    = χ [Nin]
        , effects = [(Ally, cureAll • heal 25)]
        }
      ]
    , [ newSkill
        { label   = "Medical Kit"
        , desc    = "Rin or one of her allies uses her medical kit for 3 turns, restoring 10 health each turn and strengthening their healing skills by 10 points."
        , classes = [Physical, Unremovable]
        , cost    = χ [Rand, Rand]
        , cd      = 3
        , effects = [(Ally, apply 3 [Bless 10, Heal 10])]
        }
      ]
    , invuln "Flee" "Rin" [Physical]
    ] []
  , Character
    "Obito Uchiha"
    "A member of Team Minato, Obito is treated as a nobody despite his Uchiha heritage. He dreams of becoming Hokage so that people will finally acknowledge him. Accustomed to helping from the sidelines, if he falls in battle, he will lend his strength to his allies."
    [ [ newSkill
        { label   = "Piercing Stab"
        , desc    = "Spotting an opening in his enemy's defense, Obito stabs them to deal 15 piercing damage. Deals 10 additional damage during [Sharingan]."
        , classes = [Physical, Melee]
        , cost    = χ [Rand]
        , effects = [(Enemy, withI "Sharingan" 10 pierce 15)]
        }
      ]
    , [ newSkill
        { label   = "Grand Fireball"
        , desc    = "Obito breathes searing fire on an enemy, dealing 15 affliction damage for 2 turns. During [Sharingan], this skill deals the full 30 affliction damage instantly and has no cooldown."
        , classes = [Bane, Ranged]
        , cost    = χ [Nin]
        , cd      = 1
        , effects = [(Enemy, apply 2 [Afflict 15])]
        }
      , newSkill
        { label   = "Grand Fireball"
        , desc    = "Obito breathes searing fire on an enemy, dealing 15 affliction damage for 2 turns. During [Sharingan], this skill deals the full 30 affliction damage instantly and has no cooldown."
        , classes = [Bane, Ranged]
        , cost    = χ [Nin]
        , varicd  = True
        , effects = [(Enemy, afflict 30)]
        }
      ]
    , [ newSkill
        { label   = "Sharingan"
        , desc    = "Obito targets an ally. For 4 turns, Obito gains 15 points of damage reduction, and if Obito dies, the ally will gain 5 points of damage reduction and deal 5 additional non-affliction damage."
        , classes = [Mental, Unremovable, Bypassing]
        , cost    = χ [Rand]
        , cd      = 4
        , effects = [ (XAlly, tag 4)
                    , (Self,  apply 4 [Reduce All Flat 15]
                            • trap 4 OnDeath . everyone . ifU "Sharingan" 
                              § apply' "Borrowed Sharingan" 0
                                [ Reduce All Flat 5
                                , Strengthen NonAffliction Flat 5
                                ])
                    ]
        }
      ]
    , invuln "Flee" "Obito" [Physical]
    ] []
  , Character
    "Corrupted Obito"
    "After being rescued from the brink of death by Madara, Obito has hurried back to the Hidden Leaf Village only to witness Kakashi stab Rin through the heart. With his sanity shattered by trauma and his Mangekyō Sharingan awakened, he wields the wood-shaping abilities of his Zetsu armor to rampage through the senseless hell his life has become."
    [ [ newSkill
        { label   = "Cutting Sprigs"
        , desc    = "A wooden skewer impales an enemy, dealing 20 piercing damage and permanently increasing the damage of this skill on the target by 5. Deals twice as much damage if the target is affected by [Murderous Resolve]."
        , classes = [Physical, Melee]
        , cost    = χ [Blood]
        , effects = [(Enemy, ifnotU "Murderous Resolve" 
                             § perU "Cutting Sprigs" 5 pierce 20
                           • ifU "Murderous Resolve"
                             § perU "Cutting Sprigs" 10 pierce 40
                           • addStack)]
        }
      ]
    , [ newSkill
        { label   = "Mangekyō Sharingan"
        , desc    = "Obito activates his trauma-awakened Mangekyō eye to counter the next non-mental skill used on him."
        , classes = [Chakra, Invisible, Single]
        , cost    = χ [Gen]
        , cd      = 2
        , effects = [(Self, apply 0 [Parry NonMental $ tag 1])]
        }
      ]
    , [ newSkill
        { label   = "Murderous Resolve"
        , desc    = "Obito's mind snaps and fixates obsessively on an enemy who was countered by [Mangekyō Sharingan] last turn. For 4 turns, the target's damage is weakened by 5 and they are prevented from reducing damage or becoming invulnerable."
        , require = HasU "Mangekyō Sharingan"
        , classes = [Mental, Ranged]
        , cost    = χ [Rand, Rand]
        , cd      = 5
        , effects = [(Enemy, apply 4 [Expose, Weaken All Flat 5])]
        }
      ]
    , invuln "Hide" "Obito" [Mental]
    ] []
  , Character
    "Masked Man"
    "As the Nine-Tailed Beast rampages across the Hidden Leaf Village, a mysterious masked man appears and tries to bend it to his will. The legendary beast demolishes house after house and does the same to the defenses of its enemies."
    [ [ newSkill
        { label   = "Kamui Chain Combo"
        , desc    = "The masked man snares an enemy in sealing chains and phases through them, becoming invulnerable to damage and ignoring harmful effects other than chakra cost changes for 1 turn."
        , classes = [Chakra, Melee]
        , cost    = χ [Tai]
        , cd      = 2
        , effects = [ (Self,  apply 1 [Invulnerable All])
                    , (Enemy, tag 1)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Kamui Banishment"
        , desc    = "The masked man uses a rare space-time technique to warp an enemy to his pocket dimension, dealing 20 piercing damage and making them immune to effects from their allies for 1 turn. While active, the target can only target the masked man or themselves. Deals 20 additional damage and lasts 1 additional turn if the target is affected by [Kamui Chain Combo]."
        , classes = [Chakra, Melee, Unreflectable]
        , cost    = χ [Gen]
        , cd      = 1
        , effects = [(Enemy, withU "Kamui Chain Combo" 20 pierce 20 
                           • withU "Kamui Chain Combo" 1 
                             (applyDur [Seal, Taunt]) 1)]
        }
      ]
    , [ newSkill
        { label   = "Major Summoning: Kurama"
        , desc    = "The masked man summons the Nine-Tailed Beast to the battlefield to wreak havoc, demolishing the enemy team's destructible defenses and his own destructible barrier. For 3 turns, it deals 25 damage to a random enemy. While active, the masked man and his allies ignore harmful non-damage effects other than chakra cost changes."
        , classes = [Chakra, Melee, Summon, Bypassing]
        , cost    = χ [Blood, Gen, Tai]
        , cd      = 5
        , channel = Ongoing 3
        , start   = [(Enemies, demolish)]
        , effects = [ (REnemy, damage 25) 
                    , (Allies, apply 1 [Ignore Stun])
                    ]
        }
      ]
    , invuln "Teleportation" "The masked man" [Chakra]
    ] []
  ]
