{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_HADDOCK hide #-}

module Game.Characters.Shippuden.Versions (versionCsS) where

import StandardLibrary
import Game.Functions
import Game.Game
import Game.Structure

versionCsS :: [Group -> Character]
versionCsS =
  [ let loadout = varyLoadout 1 0 0 True
    in Character
    "Nine-Tailed Naruto"
    "Rage has triggered the beast within Naruto to emerge. As his hatred grows, so does the nine-tailed beast's power. If left unchecked, Kurama may break free of his seal, and Naruto himself will cease to exist."
    [ [ newSkill
        { label   = "Four-Tailed Transformation"
        , desc    = "Naruto's rage takes over. He loses 5 health down to a minimum of 1 and gains 10 points of damage reduction and 10 permanent destructible defense. He permanently ignores all healing. His other skills become usable, and will increase in strength as his transformation progresses through further stages. Once used, this skill becomes [Six-Tailed Transformation][b][r]."
        , classes = [Chakra, Unremovable]
        , effects = [(Self, sacrifice 1 5 • defend 0 10 • loadout 0 • setFace 0
                          • apply 0 [Reduce All Flat 10, Plague])]
        }
      , newSkill
        { label   = "Six-Tailed Transformation"
        , desc    = "Naruto's fury drives him to the brink of madness. He loses 10 health down to a minimum of 1 and gains 20 points of damage reduction and 20 permanent destructible defense. He permanently ignores all non-damage effects other than chakra cost changes and is immune to effects from his allies. The power of his other skills continues to grow. Once used, this skill becomes [Nine-Tailed Transformation][b][b]."
        , classes = [Chakra, Unremovable]
        , cost    = χ [Blood, Rand]
        , effects = [(Self, remove "Four-Tailed Transformation"
                          • sacrifice 1 10 • defend 0 20 • loadout 1 • setFace 0 
                          • apply 0 [Reduce All Flat 20, Plague, Seal, Enrage])]
        }
      , newSkill
        { label   = "Nine-Tailed Transformation"
        , desc    = "As Naruto's mind is overwhelmed by wrath, the seal breaks and Kurama takes over, unlocking the full extent of his abilities. He loses 15 health down to a minimum of 1 and gains 30 points of damage reduction and 30 permanent destructible defense. Once used, this skill becomes [Raging Flames][b][r]."
        , classes = [Chakra, Unremovable]
        , cost    = χ [Blood, Blood]
        , effects = [(Self, remove "Six-Tailed Transformation"
                          • sacrifice 1 15 • defend 0 30 • loadout 2 • setFace 0
                          • apply 0 [Reduce All Flat 30, Plague, Seal, Enrage])
                    ]
        }
      , newSkill
        { label   = "Raging Flames"
        , desc    = "Finally emerging from years of imprisonment, Kurama is as cranky as he is powerful. He rains fire upon the enemy team, dealing 20 affliction damage and weakening their non-affliction damage by 10 for 1 turn."
        , classes = [Bane, Chakra, Ranged, Bypassing]
        , cost    = χ [Nin]
        , cd      = 1
        , effects = [(Enemies, afflict 20 • apply 1 [Weaken All Flat 10])]
        }
      ]
    , [ newSkill
        { label   = "Tailed Beast Bomb"
        , desc    = "Naruto launches a sphere of condensed chakra at an opponent, dealing 30 piercing damage."
        , require = HasI 1 "Four-Tailed Transformation"
        , classes = [Chakra, Ranged, Bypassing]
        , cost    = χ [Nin, Rand]
        , effects = [(Enemy, pierce 30)]
        }
      , newSkill
        { label   = "Mini Tailed Beast Bomb Barrage"
        , desc    = "Naruto fires a volley of burning chakra orbs at an enemy, dealing 10 affliction damage to them for 3 turns. If used on an enemy affected by [Clasp], this skill deals all 30 damage instantly."
        , classes = [Chakra, Ranged, Bypassing]
        , cost    = χ [Nin, Rand]
        , cd      = 1
        , channel = Action 3
        , effects = [(Enemy, ifnotU "Clasp" § afflict 10
                           • ifU "Clasp"    § afflict 30 ° delay (-1) 
                              (cancelChannel "Mini Tailed Beast Bomb Barrage"))]
        }
      , newSkill
        { label   = "Massive Tailed Beast Bomb"
        , desc    = "Kurama fires a gigantic sphere of condensed chakra at an enemy, dealing 60 piercing damage. Deals 40 additional damage if [Chakra Gathering] was used last turn."
        , classes = [Chakra, Ranged, Bypassing]
        , cost    = χ [Blood, Nin]
        , cd      = 1
        , effects = [(Enemy, withI "Chakra Gathering" 40 pierce 60)]
        }
      ]
    , [ newSkill
        { label   = "Burning Chakra Hand"
        , desc    = "Naruto extends a limb made of chakra to reach out and grab an enemy, dealing 20 damage and weakening their non-affliction damage by 5 for 1 turn."
        , require = HasI 1 "Four-Tailed Transformation"
        , classes = [Melee, Bypassing]
        , cost    = χ [Blood]
        , effects = [(Enemy, afflict 20 • apply 1 [Weaken All Flat 5])]
        }
      , newSkill
        { label   = "Clasp"
        , desc    = "Naruto breaks through an enemy's defenses and takes hold of their head, dealing 10 damage and stunning their non-mental skills for 1 turn."
        , classes = [Physical, Melee, Bypassing]
        , cost    = χ [Tai]
        , cd      = 1
        , effects = [(Enemy, damage 10 • apply 1 [Stun NonMental])]
        }
      , newSkill
        { label   = "Chakra Gathering"
        , desc    = "Kurama draws in chakra to improve his next [Tailed Beast Bomb]."
        , classes = [Chakra]
        , cost    = χ [Rand, Rand, Rand, Rand]
        , cd      = 3
        , effects = [(Self, tag 1)]
        }
      ]
     , [ invuln1 "Chakra Skin" "Naruto" [Chakra]
       , invuln1 "Hide" "Naruto" [Mental]
       , invuln1 "Block" "Kurama" [Physical]
       ]
    ] []
  , Character
    "Curse Mark Sasuke"
    "After training under Orochimaru for years, Sasuke has become a rogue ninja with complete control over his curse mark. With unlimited access to his strength and chakra, Sasuke empowers his abilities with dark energy and can even fly."
    [ [ newSkill
        { label   = "Sharingan"
        , desc    = "The dark energy of Sasuke's curse mark infuses his Sharingan, providing 10 points of damage reduction for 3 turns. While active, Sasuke ignores non-damage harmful effects other than chakra cost changes."
        , classes = [Mental, Unremovable]
        , cost    = χ [Blood]
        , cd      = 3
        , effects = [(Self, apply 3 [Reduce All Flat 10, Enrage])]
        }
      ]
    , [ newSkill
        { label   = "Chidori"
        , desc    = "Sasuke attacks an enemy from above, dealing 20 piercing damage and weakening their non-affliction damage by 10 for 1 turn. Deals 10 additional damage during [Sharingan]. If this skill kills an enemy, [Sharingan Genjutsu] will be applied to a random enemy."
        , classes = [Chakra, Melee, Bypassing]
        , cost    = χ [Nin]
        , effects = [ (Enemy,  withI "Sharingan" 10 (execute pierce) 20 
                             • apply 1 [Weaken All Flat 10])
                    , (REnemy, ifI "executed" § withI "Sharingan" 1 
                               (\i -> trapWith TrapTo [Invisible] 
                                     i OnReflectAll identity) 1)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Sharingan Genjutsu"
        , desc    = "Sasuke traps an enemy in an illusion that makes them believe they got the upper hand. For 1 turn, any skill that the target uses on Sasuke or his allies is reflected back to them. Lasts 1 additional turn and costs two genjutsu chakra during [Sharingan]."
        , classes = [Mental, Ranged, Invisible]
        , cost    = χ [Gen]
        , cd      = 4
        , effects = [(Enemy, withI "Sharingan" 1 
                             (\i -> trap i OnReflectAll identity) 1)]
        , changes = changeWith "Sharingan" $ setCost [Gen, Gen]
        }
      ]
    , invuln "Snake Shedding" "Sasuke" [Physical]
    ] []
  , Character
    "Mangekyō Sasuke"
    "Sasuke has finally slain his brother to avenge his clan, only to discover that Itachi had been protecting him from the start. Full of undirected anger, he uses his newly awakened mangekyō sharingan to strike back at anyone who gets in his way."
    [ [ newSkill
        { label   = "Susano'o"
        , desc    = "Using the mangekyō sharingan's signature ability, Sasuke creates a colossus of chakra around himself. For 3 turns, all damage to Sasuke—including piercing and affliction—is reduced by 15 points."
        , classes = [Chakra, Single]
        , cost    = χ [Blood]
        , cd      = 4
        , effects = [(Self, apply 3 [Reduce Affliction Flat 15] 
                          • vary' 3 "Chidori" "Blazing Arrow"
                          • vary' 3 "Amaterasu" "Yasaka Beads"
                          • setFace 3 )]
        }
      ]
    , [ newSkill
        { label   = "Chidori"
        , desc    = "Sasuke hurls lightning energy at an enemy, dealing 20 piercing damage and stunning their melee skills for 1 turn. Next turn, Sasuke gains 15 points of physical damage reduction. If no new physical skills are used on Sasuke by the end of the turn, the cost of this skill becomes 1 ninjutsu chakra and its cooldown resets. During [Susano'o], this skill becomes [Blazing Arrow][b][r]."
        , classes = [Chakra, Melee]
        , cost    = χ [Nin, Rand]
        , cd      = 2
        , effects = [ (Enemy, pierce 20 • apply 1 [Stun All])
                    , (Self,  trap (-1) (OnDamaged Physical) 
                              § remove "Chidori"
                            • bomb (-1) [Reduce Physical Flat 15]
                              [(Expire, hide 1 [] • reset "Chidori" "")] 
                      )
                    ]
        , changes = changeWith "Chidori" $ setCost [Nin]
        }
      , newSkill
        { label   = "Blazing Arrow"
        , desc    = "Sasuke forges three arrows out of flame and shoots them one after another at an enemy, dealing 15 damage for 3 turns. If this skill is stunned, Sasuke deals the remaining damage instantly and the cooldown of this skill resets."
        , classes = [Chakra, Ranged, Resource]
        , cost    = χ [Blood, Rand]
        , cd      = 3
        , channel = Action 3
        , start   = [ (Self, remove "Blazing Arrow" 
                           • addStacks "Blazing Arrow" 3) 
                    ]
        , effects = [ (Enemy, damage 15) 
                    , (Self,  removeStack "Blazing Arrow")
                    ]
        , disrupt = [ (Enemy, perI "Blazing Arrow" 15 damage 0)
                    , (Self,  remove "Blazing Arrow"
                            • cancelChannel "Blazing Arrow" 
                            • reset "Chidori" "Blazing Arrow")
                    ]
        }
      ]
    , [ newSkill
        { label   = "Amaterasu"
        , desc    = "Sasuke ignites an enemy, dealing 5 affliction damage to them for 4 turns. If the target becomes invulnerable, they are cured of the effect. During [Susano'o], this skill becomes [Yasaka Beads][n]. Each time an enemy is cured of [Amaterasu], the damage of [Amaterasu] and [Yasaka Beads] permanently increases by 5."
        , classes = [Bane, Chakra, Ranged, Unreflectable]
        , cost    = χ [Blood]
        , cd      = 1
        , effects = [(Enemy, trap 4 OnImmune § removeTrap "Amaterasu"
                                              ° remove "Amaterasu"
                           • perI "Amaterasu" 5 
                             (\i -> bomb 4 [Afflict i] 
                                   [(Remove, self § addStack)]) 
                             5)]
        }
      , newSkill
        { label   = "Yasaka Beads"
        , desc    = "Sasuke attacks an enemy with a Magatama of black flame, dealing 10 affliction damage. Damage permanently increases by 5 each time an enemy is cured of [Amaterasu]. If the target uses a skill next turn, they take 10 additional affliction damage. If they receive any healing next turn, this skill deals 20 additional damage for 1 turn."
        , classes = [Chakra, Ranged]
        , cost    = χ [Nin]
        , effects = [(Enemy, withI "Yasaka Beads" 20 
                            (perI "Amaterasu" 5 afflict) 10
                           • trap (-1) (OnAction All) § afflict 10
                           • trap 1 OnHealed . self § tag 1)]
        }
      ]
    , invuln' "Mangekyō Foresight" 
              "Sasuke becomes invulnerable for 1 turn. Extends the duration of [Susano'o] by 1 turn." 
              [Mental]
              [prolong 1 "Susano'o"]
    ] []
  , Character
    "Commander Gaara"
    "Coordinating the Allied Shinobi Forces and personally commanding the Fourth Division, Gaara has proven to be an inspiring leader and talented strategist. His attacks scatter sand particles around the battlefield, which he draws back in with explosive force."
    [ [ newSkill
        { label   = "Sand Grasp"
        , desc    = "Gaara grabs an enemy with sand, first adding a Sand Bomb to them and then dealing 10 damage. Deals 5 additional damage per Sand Bomb on the target. Has no chakra cost during [Sand Mausoleum Seal]. Targets all enemies during [Mother's Embrace]."
        , classes = [Physical, Ranged]
        , cost    = χ [Rand]
        , effects = [(Enemy, perU "Sand Bomb" 5 damage 15 
                           • apply' "Sand Bomb" 0 [])]
        , changes = changeWith "Sand Mausoleum Seal" § setCost []
                 •• changeWith "Mother's Embrace"    § targetAll
        }
      ]
    , [ newSkill
        { label   = "Mother's Embrace"
        , desc    = "The soul of Gaara's deceased mother protects him with a shield of sand, providing 40 destructible defense for 3 turns. As long as Gaara has destructible defense from this skill, he ignores harmful non-damage effects other than chakra cost changes."
        , classes = [Physical]
        , cost    = χ [Blood, Rand]
        , cd      = 4
        , effects = [(Self, defend 3 50 • onBreak' • apply 3 [Enrage])]
        }
      ]
    , [ newSkill
        { label   = "Sand Mausoleum Seal"
        , desc    = "Dense layers of sand entomb Gaara's enemies in a giant pyramid, dealing 15 damage to all enemies for 3 turns and increasing the costs of their skills by 1 random chakra. Each turn, deals 5 additional damage to each enemy per Sand Bomb on them and removes all Sand Bombs."
        , classes = [Physical, Ranged]
        , cost    = χ [Blood, Nin, Rand]
        , cd      = 4
        , channel = Action 3
        , effects = [ (Enemies, perU "Sand Bomb" 5 damage 15 
                              • apply 1 [Exhaust All]) 
                    , (Everyone, remove "Sand Bomb")
                    ]
        }
      ] 
    , invuln "Sand Shield" "Gaara" [Physical]
    ] []
  , Character
    "Sage Mode Kabuto"
    "Unable to find an identity of his own, Kabuto has spent his life taking on the traits of others. Years of research and experimenting upon himself have reached their conclusion, and now Kabuto prepares for his final metamorphosis."
    [ [ newSkill
        { label   = "Sage Transformation"
        , desc    = "By synthesizing rare genetic traits from other bloodlines inside his body, Kabuto becomes attuned to the flow of natural energy. Each turn, the chakra costs and type of chakra gained from his other skills cycle through the different types of chakra. Once used, this skill becomes [DNA Transmission Shadow][r][r][r]."
        , classes = [Chakra]
        , cost    = χ [Rand, Rand, Rand]
        , channel = Ongoing 0
        , effects = [(Self, delay (-1) kabuto)]
        }
      , newSkill
        { label   = "DNA Transmission Shadow"
        , desc    = "Kabuto focuses his attention on producing a clone of a dead ally. If he is not stunned during the next turn, the ally comes back to life at full health, removing all effects from them and resetting their cooldowns. They are stunned for the first turn after being created. The clone remains connected to him, and harmful non-damage effects on one are also applied to the other. Using this skill again destroys the current clone."
        , classes = [Chakra, Necromancy, Unremovable, Unreflectable]
        , cost    = χ [Rand, Rand, Rand]
        , channel = Control 1
        , start   = [ (Self,  hide' "dna" 1 []
                            • everyone § ifU "DNA Transmission Shadow" kill')
                    , (XAlly, delay (-1) . ifI "dna" 
                            $ factory
                            • apply 0 [Share]
                            • apply 1 [Stun All]
                            • self § hide' "Transmission" 0 [Share])
                    ]
        , disrupt = [(Self, remove "dna")]
        }
      , newSkill
        { label   = "DNA Transmission Shadow"
        , desc    = "Kabuto focuses his attention on producing a clone of a dead ally. If he is not stunned during the next turn, the ally comes back to life at full health, removing all effects from them and resetting their cooldowns. They are stunned for the first turn after being created. The clone remains connected to him, and harmful non-damage effects on one are also applied to the other. Using this skill again destroys the current clone."
        , classes = [Chakra, Necromancy, Unremovable, Unreflectable]
        , cost    = χ [Blood, Blood, Blood]
        , channel = Control 1
        , start   = [ (Self,  hide' "dna" 1 []
                            • everyone § ifU "DNA Transmission Shadow" kill')
                    , (XAlly, delay (-1) . ifI "dna" 
                            $ factory
                            • apply 0 [Share]
                            • apply 1 [Stun All]
                            • self § hide' "Transmission" 0 [Share])
                    ]
        , disrupt = [(Self, remove "dna")]
        }
      , newSkill
        { label   = "DNA Transmission Shadow"
        , desc    = "Kabuto focuses his attention on producing a clone of a dead ally. If he is not stunned during the next turn, the ally comes back to life at full health, removing all effects from them and resetting their cooldowns. They are stunned for the first turn after being created. The clone remains connected to him, and harmful non-damage effects on one are also applied to the other. Using this skill again destroys the current clone."
        , classes = [Chakra, Necromancy, Unremovable, Unreflectable]
        , cost    = χ [Gen, Gen, Gen]
        , channel = Control 1
        , start   = [ (Self,  hide' "dna" 1 []
                            • everyone § ifU "DNA Transmission Shadow" kill')
                    , (XAlly, delay (-1) . ifI "dna" 
                            $ factory
                            • apply 0 [Share]
                            • apply 1 [Stun All]
                            • self § hide' "Transmission" 0 [Share])
                    ]
        , disrupt = [(Self, remove "dna")]
        }
      , newSkill
        { label   = "DNA Transmission Shadow"
        , desc    = "Kabuto focuses his attention on producing a clone of a dead ally. If he is not stunned during the next turn, the ally comes back to life at full health, removing all effects from them and resetting their cooldowns. They are stunned for the first turn after being created. The clone remains connected to him, and harmful non-damage effects on one are also applied to the other. Using this skill again destroys the current clone."
        , classes = [Chakra, Necromancy, Unremovable, Unreflectable]
        , cost    = χ [Nin, Nin, Nin]
        , channel = Control 1
        , start   = [ (Self,  hide' "dna" 1 []
                            • everyone § ifU "DNA Transmission Shadow" kill')
                    , (XAlly, delay (-1) . ifI "dna" 
                            $ factory
                            • apply 0 [Share]
                            • apply 1 [Stun All]
                            • self § hide' "Transmission" 0 [Share])
                    ]
        , disrupt = [(Self, remove "dna")]
        }
      , newSkill
        { label   = "DNA Transmission Shadow"
        , desc    = "Kabuto focuses his attention on producing a clone of a dead ally. If he is not stunned during the next turn, the ally comes back to life at full health, removing all effects from them and resetting their cooldowns. They are stunned for the first turn after being created. The clone remains connected to him, and harmful non-damage effects on one are also applied to the other. Using this skill again destroys the current clone."
        , classes = [Chakra, Necromancy, Unremovable, Unreflectable]
        , cost    = χ [Tai, Tai, Tai]
        , channel = Control 1
        , start   = [ (Self,  hide' "dna" 1 []
                            • everyone § ifU "DNA Transmission Shadow" kill')
                    , (XAlly, delay (-1) . ifI "dna" 
                            $ factory
                            • apply 0 [Share]
                            • apply 1 [Stun All]
                            • self § hide' "Transmission" 0 [Share])
                    ]
        , disrupt = [(Self, remove "dna")]
        }
      ] 
    , [ newSkill
        { label   = "Inorganic Animation"
        , desc    = "Kabuto brings his surroundings to life, dealing 10 damage to all enemies. The shifting obstacles protect Kabuto's team, forcing enemies to target specific opponents with skills that would normally affect all opponents. If this skill damages any enemies, [Transfusion] and [White Extreme Attack] are recharged."
        , classes = [Physical, Ranged, Unreflectable]
        , cost    = χ [Rand]
        , effects = [ (Self,    trap' (-1) OnDamage § resetCharges
                              • enemyTeam § apply 1 [Restrict])
                    , (Enemies, damage 10)
                    ]
        }
      , newSkill
        { label   = "Inorganic Animation"
        , desc    = "Kabuto brings his surroundings to life, dealing 10 damage to all enemies. The shifting obstacles protect Kabuto's team, forcing enemies to target specific opponents with skills that would normally affect all opponents. If this skill damages any enemies, [Transfusion] and [White Extreme Attack] are recharged."
        , classes = [Physical, Ranged, Unreflectable]
        , cost    = χ [Blood]
        , effects = [ (Self,    trap' (-1) OnDamage § resetCharges
                              • enemyTeam § apply 1 [Restrict])
                    , (Enemies, damage 10)
                    ]
        }
      , newSkill
        { label   = "Inorganic Animation"
        , desc    = "Kabuto brings his surroundings to life, dealing 10 damage to all enemies. The shifting obstacles protect Kabuto's team, forcing enemies to target specific opponents with skills that would normally affect all opponents. If this skill damages any enemies, [Transfusion] and [White Extreme Attack] are recharged."
        , classes = [Physical, Ranged, Unreflectable]
        , cost    = χ [Gen]
        , effects = [ (Self,    trap' (-1) OnDamage § resetCharges
                              • enemyTeam § apply 1 [Restrict])
                    , (Enemies, damage 10)
                    ]
        }
      , newSkill
        { label   = "Inorganic Animation"
        , desc    = "Kabuto brings his surroundings to life, dealing 10 damage to all enemies. The shifting obstacles protect Kabuto's team, forcing enemies to target specific opponents with skills that would normally affect all opponents. If this skill damages any enemies, [Transfusion] and [White Extreme Attack] are recharged."
        , classes = [Physical, Ranged, Unreflectable]
        , cost    = χ [Nin]
        , effects = [ (Self,    trap' (-1) OnDamage § resetCharges
                              • enemyTeam § apply 1 [Restrict])
                    , (Enemies, damage 10)
                    ]
        }
      , newSkill
        { label   = "Inorganic Animation"
        , desc    = "Kabuto brings his surroundings to life, dealing 10 damage to all enemies. The shifting obstacles protect Kabuto's team, forcing enemies to target specific opponents with skills that would normally affect all opponents. If this skill damages any enemies, [Transfusion] and [White Extreme Attack] are recharged."
        , classes = [Physical, Ranged, Unreflectable]
        , cost    = χ [Tai]
        , effects = [ (Self,    trap' (-1) OnDamage § resetCharges
                              • enemyTeam § apply 1 [Restrict])
                    , (Enemies, damage 10)
                    ]
        }
      ]
    , [ newSkill
        { label   = "Transfusion"
        , desc    = "Kabuto administers chakra-rich blood to himself or an ally, restoring 15 health for 3 turns and resetting the target's cooldowns. Kabuto gains a random chakra."
        , classes = [Chakra, Unremovable]
        , charges = 1
        , effects = [ (Ally, resetAll • apply 3 [Heal 15]) 
                    , (Self, gain [Rand])
                    ]
        }
      , newSkill
        { label   = "Transfusion"
        , desc    = "Kabuto administers chakra-rich blood to himself or an ally, restoring 15 health for 3 turns and resetting the target's cooldowns. Kabuto gains a bloodline chakra."
        , classes = [Chakra, Unremovable]
        , charges = 1
        , effects = [ (Ally, resetAll • apply 3 [Heal 15]) 
                    , (Self, gain [Blood])
                    ]
        }
      , newSkill
        { label   = "Transfusion"
        , desc    = "Kabuto administers chakra-rich blood to himself or an ally, restoring 15 health for 3 turns and resetting the target's cooldowns. Kabuto gains a genjutsu chakra."
        , classes = [Chakra, Unremovable]
        , charges = 1
        , effects = [ (Ally, resetAll • apply 3 [Heal 15]) 
                    , (Self, gain [Gen])
                    ]
        }
      , newSkill
        { label   = "Transfusion"
        , desc    = "Kabuto administers chakra-rich blood to himself or an ally, restoring 15 health for 3 turns and resetting the target's cooldowns. Kabuto gains a ninjutsu chakra."
        , classes = [Chakra, Unremovable]
        , charges = 1
        , effects = [ (Ally, resetAll • apply 3 [Heal 15]) 
                    , (Self, gain [Nin])
                    ]
        }
      , newSkill
        { label   = "Transfusion"
        , desc    = "Kabuto administers chakra-rich blood to himself or an ally, restoring 15 health for 3 turns and resetting the target's cooldowns. Kabuto gains a taijutsu chakra."
        , classes = [Chakra, Unremovable]
        , charges = 1
        , effects = [ (Ally, resetAll • apply 3 [Heal 15]) 
                    , (Self, gain [Tai])
                    ]
        } 
      ]
    , [ newSkill
        { label   = "White Extreme Attack"
        , desc    = "Shuttering the brille over his eyes, Kabuto shoots a chakra dragon from his mouth which explodes in a flash of light that stuns all allies and enemies for 1 turn. Kabuto gains 2 random chakra."
        , classes = [Chakra, Ranged]
        , cd      = 3
        , charges = 1
        , effects = [ (Self,    gain [Rand, Rand]) 
                    , (XAllies, apply 1 [Stun All])
                    , (Enemies, apply 1 [Stun All])
                    ]
        }
      , newSkill
        { label   = "White Extreme Attack"
        , desc    = "Shuttering the brille over his eyes, Kabuto shoots a chakra dragon from his mouth which explodes in a flash of light that stuns all allies and enemies for 1 turn. Kabuto gains 2 bloodline chakra."
        , classes = [Chakra, Ranged]
        , cd      = 3
        , charges = 1
        , effects = [ (Self,    gain [Blood, Blood]) 
                    , (XAllies, apply 1 [Stun All])
                    , (Enemies, apply 1 [Stun All])
                    ]
        }
      , newSkill
        { label   = "White Extreme Attack"
        , desc    = "Shuttering the brille over his eyes, Kabuto shoots a chakra dragon from his mouth which explodes in a flash of light that stuns all allies and enemies for 1 turn. Kabuto gains 2 genjutsu chakra."
        , classes = [Chakra, Ranged]
        , cd      = 3
        , charges = 1
        , effects = [ (Self,    gain [Gen, Gen]) 
                    , (XAllies, apply 1 [Stun All])
                    , (Enemies, apply 1 [Stun All])
                    ]
        }
      , newSkill
        { label   = "White Extreme Attack"
        , desc    = "Shuttering the brille over his eyes, Kabuto shoots a chakra dragon from his mouth which explodes in a flash of light that stuns all allies and enemies for 1 turn. Kabuto gains 2 ninjutsu chakra."
        , classes = [Chakra, Ranged]
        , cd      = 3
        , charges = 1
        , effects = [ (Self,    gain [Nin, Nin]) 
                    , (XAllies, apply 1 [Stun All])
                    , (Enemies, apply 1 [Stun All])
                    ]
        }
      , newSkill
        { label   = "White Extreme Attack"
        , desc    = "Shuttering the brille over his eyes, Kabuto shoots a chakra dragon from his mouth which explodes in a flash of light that stuns all allies and enemies for 1 turn. Kabuto gains 2 taijutsu chakra."
        , classes = [Chakra, Ranged]
        , cd      = 3
        , charges = 1
        , effects = [ (Self,    gain [Tai, Tai]) 
                    , (XAllies, apply 1 [Stun All])
                    , (Enemies, apply 1 [Stun All])
                    ]
        }
      ]
    ] []
  , Character
    "Eight-Gates Guy"
    "With the fate of the world at stake, Guy has opened all eight Gates and is holding nothing back. The effort will surely kill him, but while he lives, his strength outmatches even the legendary Madara Uchiha."
    [ [ newSkill
        { label   = "Evening Elephant"
        , desc    = "Using a devastating sequence of punches, Guy deals 20 damage to an enemy. For 1 turn, they are immune to effects from allies and their nonmental skills are stunned. Guy loses 20 health down to a minimum of 1. Each time this skill is used, it permanently deals 20 additional damage and costs 1 additional random chakra."
        , classes = [Physical, Melee, Uncounterable, Unreflectable]
        , cost    = χ [Tai]
        , effects = [ (Enemy, perI "Evening Elephant" 20 damage 20
                            • apply 1 [Seal, Stun NonMental])
                    , (Self,  sacrifice 1 20 • addStack)
                    ]
        , changes = costPer "Evening Elephant" [Rand]
        }
      ]
    , [ newSkill
        { label   = "Battle Stance"
        , desc    = "Next turn, Guy will deal double damage and ignore harmful non-damage effects other than chakra cost changes. Guy loses 10 health down to a minimum of 1."
        , classes = [Physical, Unremovable]
        , cost    = χ [Tai]
        , cd      = 2
        , effects = [(Self, sacrifice 1 10 
                          • apply 1 [Enrage, Strengthen All Percent 200])]
        }
      ]
    , [ newSkill
        { label   = "Night Guy"
        , desc    = "As his blood evaporates into mist around him, Guy warps time and space to instantly attack an enemy, dealing 50 piercing damage. For 2 turns, the target is immune to effects from allies, their damage is weakened by 5, and Guy cannot be healed. Guy loses 30 health down to a minimum of 1. Each time this skill is used, it permanently deals 25 additional damage and costs 1 additional taijutsu chakra."
        , classes = [Physical, Melee, Bypassing, Uncounterable, Unreflectable]
        , cost    = χ [Tai, Tai]
        , cd      = 2
        , effects = [ (Enemy, perI "Night Guy" 25 pierce 50 
                            • apply 2 [Seal, Weaken All Flat 5])
                    , (Self,  sacrifice 1 30 • addStack • apply 2 [Plague])
                    ]
        , changes = costPer "Night Guy" [Tai]   
        }
      ]
    , invuln "Dodge" "Guy" [Physical]
    ] []
  , Character
    "Susano'o Itachi"
    "Plagued by a lethal disease that saps his strength, Itachi has been forced to go on the defensive. Out of other options, he now plays his trump card: the legendary armor Susano'o, created by the power of the mangekyō sharingan."
    [ [ newSkill
        { label   = "Skeletal Susano'o"
        , desc    = "A bare skeleton, the first layer of Susano'o, forms around Itachi. All damage he receives—including piercing and affliction—is permanently reduced by 5. Each turn for the next 3 turns, Itachi gains 5 points of destructible defense. After 3 turns, this skill becomes [Armored Susano'o][b][b]."
        , classes = [Chakra, Unremovable]
        , cost    = χ [Rand]
        , charges = 1
        , channel = Ongoing 3
        , start   = [(Self, apply 0 [Reduce Affliction Flat 5] 
                          • delay (-3) § vary' 0 "Skeletal Susano'o" 
                                                 "Armored Susano'o"
                          • hide' "susan" 0 [])]
        , effects = [(Self, defend 0 5)]
        }
      , newSkill
        { label   = "Armored Susano'o"
        , desc    = "Using the full power of his mangekyō sharingan, Itachi causes ethereal muscles and skin to knit across the skeleton of Susano'o, providing 40 points of destructible defense for 2 turns. While he has destructible defense from this skill, he ignores stuns, the costs of his skills are decreased by 1 random chakra, and he is immune to affliction damage. All damage he receives—including piercing and affliction—is permanently reduced by 10, non-stacking."
        , classes = [Chakra, Unremovable, Nonstacking]
        , cost    = χ [Blood, Blood]
        , cd      = 4
        , effects = [(Self, apply' "Armored Susano'o " 0 
                            [Reduce Affliction Flat 10] 
                          • defend 2 40 • onBreak'
                          • apply 2 
                            [Ignore Stun, Invulnerable Affliction, Unexhaust])]
        }
      ]
    , [ newSkill
        { label   = "Totsuka Blade"
        , desc    = "Itachi slashes an enemy with an ethereal liquid blade, dealing 25 affliction damage."
        , require = HasI 1 "susan"
        , classes = [Chakra, Melee, Bypassing, Uncounterable, Unreflectable]
        , cost    = χ [Gen, Rand]
        , effects = [(Enemy, perU "Hangover" 5 afflict 25 • tag 1)]
        }
      ]
    , [ newSkill
        { label   = "Sealing Jar of Drunken Dreams"
        , desc    = "Itachi seals an enemy within the ethereal sake jar from which the Totsuka Blade is formed, removing a random chakra from them. For 1 turn, they are stunned and immune to effects from allies. The target permanently takes 5 additional damage from Totsuka Blade. Can only be used on a target who was affected by [Totsuka Blade] last turn."
        , require = HasU "Totsuka Blade"
        , classes = [Chakra, Ranged]
        , cost    = χ [Blood, Rand]
        , effects = [(Enemy, drain 1 • apply 1 [Stun All, Seal] 
                                     • apply' "Sealed" 0 [])]
        }
      ]
    , [ newSkill
        { label   = "Yata Mirror"
        , desc    = "Itachi becomes invincible for 1 turn. While active, every harmful skill used on him deals 10 damage to its user and causes Itachi to gain 10 destructible defense."
        , require = HasI 1 "susan"
        , classes = [Chakra, Invisible, Unremovable]
        , cost    = χ [Gen]
        , cd      = 3
        , effects = [(Self, apply 1 [Invincible All, Enrage] 
                          • trapFrom 1 (OnHarmed All) 
                            § damage 10 ° self (defend 0 10))]
        }
      ]
    ] []
  ]
