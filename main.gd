extends Node2D
signal payout_signal(w)

# Colors: BG_Blue: 0,0,160  DK_Blue: 0,0,64  Yellow: 224,224,0  Red: 192,0,0

var values: Array[int] # Card values
var suits: Array[String] # Card suits
var card: Card
var deck: Array[Card] # A deck of 52 Card objects.
var fresh_deck: Array[Card] # Unshuffled deck of cards.
var card_back_color: String
var card_backs_showing: bool
var hand_values: Array[int]
var hand_suits: Array[String]
var dealt_hand: Array[Card]
var draw_hand: Array[Card]
var final_hand: Array[Card]
var held_cards: Array[bool] 
var hand_name: String
var new_hand: bool
var bet_amt: int
var win_amt: int
var credits: int
var fl: bool # flush
var st: bool # straight
var hands_played: int
var deal_texture
var drawTexture
var is_paying: bool
var high_credits: int
var low_credits: int
var rand_card_back: int

func _ready(): # ===== READY =====
	randomize() # Reseed the RNG.
	rand_card_back = randi_range(0,1)
	#print(rand_card_back)
	for x in range(13): # Fill values array with numbers 2 through 14.
		values.append(x+2) # 11=J, 12=Q, 13=K, 14=A.
	suits = ['C','D','H','S'] # Array of the 4 suits.
	bet_amt = 5 # default bet amt
	$UI/Control/BetLabel.text = "BET  " + str(bet_amt)
	$InfoBox.visible = false
	
	# get payout_signal
	payout_signal.connect(payout_sig)
	
	# get deal_signal
	$UI.deal_signal.connect(deal_draw_sig)
	
	# get bet signals
	$UI.bet_one_signal.connect(bet_one_sig)
	$UI.bet_max_signal.connect(bet_max_sig)
	# get info signal
	$UI.info_signal.connect(info_sig)
	
	# get hold_sig from cards
	$Card0.hold_signal.connect(hold_sig)
	$Card1.hold_signal.connect(hold_sig)
	$Card2.hold_signal.connect(hold_sig)
	$Card3.hold_signal.connect(hold_sig)
	$Card4.hold_signal.connect(hold_sig)

	credits = 100
	high_credits = credits
	low_credits = credits
	update_credits()
	hands_played = 0
	clear_held_cards()
	new_hand = true
	hand_name = ""
	card_back_color = "blue_card_back.png" if rand_card_back == 0 else "red_card_back.png"
	card_backs_showing = true
	
	# Make a fresh deck of cards,
	open_fresh_deck() 	# which we'll create only once per session.
	show_card_backs()
	#$HoldTimer.start()
	deal_texture = preload("res://assets/deal_button.png")
	drawTexture = preload("res://assets/draw_button.png")
	is_paying = false
	show_bet_amt_column()
	$CrowdNoise.play()
	
	#test.append(Sprite2D.new()) # Just testing ...
	
func _process(_delta): # ========================== This IS the GAME LOOP ======
	# === quit game === 
		# === Deal_Draw input ===
	if Input.is_action_just_released("Deal_Draw") and new_hand and !is_paying: # spacebar or Deal button
		$UI/Control/DealDrawButton.texture_normal = deal_texture
		if $InfoBox.visible:
			info_sig()
		if bet_amt == 0: # No $$, no play!
				$CrowdNoise.stop()
				OS.alert("You have no credits! Game OVER!")
				game_over()
		else:
			
			clear_winning_hand_color()
			if bet_amt > credits:
				bet_amt = credits
				show_bet_amt_column()
			$UI/Control/BetLabel.text = "BET  " + str(bet_amt)
			dealt_hand.clear()
			draw_hand.clear()
			final_hand.clear()
			new_hand = false
			credits -= bet_amt
			update_credits()
			hand_name = ''
			$UI/Control/WinHandLabel.text = hand_name
			$UI/Control/WinAmtLabel.text = 'WIN  '
			#open_fresh_deck()
			shuffle_deck()
			clear_held_cards()
			if not card_backs_showing:
				show_card_backs()
				await get_tree().create_timer(.5).timeout
			card_backs_showing = false
			deal_hand()
			show_cards(dealt_hand) # showing in deal_hand() right now
			#evaluate_pre-draw_hand()
			$UI/Control/DealDrawButton.texture_normal = drawTexture
	elif Input.is_action_just_released("Deal_Draw") and !new_hand and !is_paying: # spacebar or Draw button
		if $InfoBox.visible:
			info_sig()
		show_card_backs()
		await get_tree().create_timer(.5).timeout
		draw_cards()
		show_cards(final_hand) # showing in draw_cards() right now
		evaluate_final_hand(final_hand)
		update_credits()
		high_credits = credits if credits > high_credits else high_credits
		low_credits = credits if credits < low_credits else low_credits
		if credits < 1:
			bet_amt = 0
		print(hand_name) if len(hand_name) > 0 else print(" -- nothing --") # ternary operator!
		print("Payout: $%d." % win_amt)
		print("Credits: $%d." % credits)
		hands_played += 1
		print("Hands played: " + str(hands_played) + "\n")
		new_hand = true
		$UI/Control/DealDrawButton.texture_normal = deal_texture
		
	

		
	# === Get Bet amount input ===
	if Input.is_action_just_pressed("Bet_Less") and new_hand and bet_amt > 0 and !is_paying: # < key
		change_bet(-1)
		#show_bet_amt_column()
	if Input.is_action_just_pressed("Bet_More") and new_hand and bet_amt > 0 and !is_paying: # > key
		change_bet(1)
		#show_bet_amt_column()	
	
		
	# === Hold/Unhold input ===
	if !new_hand and !is_paying:
		if Input.is_action_just_pressed("Hold_0"): # 1 key
			hold_card(0)
		if Input.is_action_just_pressed("Hold_1"): # 2 key
			hold_card(1)
		if Input.is_action_just_pressed("Hold_2"): # 3 key
			hold_card(2)
		if Input.is_action_just_pressed("Hold_3"): # 4 key
			hold_card(3)
		if Input.is_action_just_pressed("Hold_4"): # 5 key
			hold_card(4)

# ========= User Functions ===============

func hold_sig(num):
	var hold_num: String = "Hold_" + str(num)
	Input.action_press(hold_num)
	Input.action_release(hold_num)

func deal_draw_sig():
	Input.action_press("Deal_Draw")
	Input.action_release("Deal_Draw")

func payout_sig(w):
	var amt: int = 0
	is_paying = true
	$PayoutTimer.wait_time = 0.005 if w > 45 else 0.025
	$PayoutTimer.start()
	for x in range(w):
		amt += 1
		$UI/Control/WinAmtLabel.text = "WIN " + str(amt)
		await $PayoutTimer.timeout
	is_paying = false
		
func bet_one_sig():
	if new_hand and !is_paying:
		bet_amt += 1
		if bet_amt > 5: bet_amt = 1
		if bet_amt > credits :
			bet_amt = credits
		$UI/Control/BetLabel.text = "BET  " + str(bet_amt)
		show_bet_amt_column()
	
func bet_max_sig():
	if new_hand and !is_paying:
		bet_amt = 5
		if bet_amt > credits :
			bet_amt = credits
		$UI/Control/BetLabel.text = "BET  " + str(bet_amt)
		show_bet_amt_column()
		
func info_sig():
	var box_text: String
	var avg_wl: float
	
	avg_wl = (credits - 100.0) / hands_played
	box_text = "Hands played: %s \n" % hands_played
	box_text += "Avg win/loss per hand: $%.2f \n" % avg_wl
	box_text += "High/Low credits: %s / %s" % [high_credits, low_credits]
	
	$InfoBox.text = box_text
#	
	if $JOBLogo.self_modulate == Color(1,1,1,1):
		$JOBLogo.self_modulate = Color(1,1,1,0.15)
		$InfoBox.visible = true
	else:
		$InfoBox.visible = false
		$JOBLogo.self_modulate = Color(1,1,1,1)
	
#func set_bet(amt):
#	bet_amt = amt
#
#	if bet_amt > 5:
#		bet_amt = 5
#	if bet_amt < 1:
#		bet_amt = 1
#	if bet_amt > credits and credits > 0:
#		bet_amt = credits
#
#	$UI/Control/BetLabel.text = "BET  " + str(bet_amt)				
	
func change_bet(amt): # this is for using the < and > keys
	bet_amt += amt
	
	if bet_amt > 5:
		bet_amt = 5
	if bet_amt < 1:
		bet_amt = 1
	if bet_amt > credits:
		bet_amt = credits
	$UI/Control/BetLabel.text = "BET  " + str(bet_amt)				
	show_bet_amt_column()

func hold_card(n):
	held_cards[n] = !held_cards[n]
	show_held_labels(held_cards)

func clear_winning_hand_color():
	$UI/Control/PayTableGrid/TableLabel0.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel6.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel12.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel18.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel24.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel30.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel36.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel42.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel48.set("theme_override_colors/font_color", null)
	$UI/Control/PayTableGrid/TableLabel48.set("theme_override_colors/font_color", null)
	
func show_bet_amt_column():
	if bet_amt == 1 : 
		$B1Rect.visible = true
	else:
		$B1Rect.visible = false
		
	if bet_amt == 2 : 
		$B2Rect.visible = true
	else:
		$B2Rect.visible = false
		
	if bet_amt == 3 : 
		$B3Rect.visible = true
	else:
		$B3Rect.visible = false
		
	if bet_amt == 4 : 
		$B4Rect.visible = true
	else:
		$B4Rect.visible	= false
		
	if bet_amt == 5 : 
		$B5Rect.visible = true
	else:
		$B5Rect.visible = false
		
	#print('In show_bet_amt_column.')	

func show_cards(h):
	#$FlipTimer.start()
	if not held_cards[0]:
		$Card0.texture = load("res://assets/cards/"+ h[0].get_card_image())
		await $FlipTimer.timeout
	if not held_cards[1]:
		$Card1.texture = load("res://assets/cards/"+ h[1].get_card_image())
		await $FlipTimer.timeout
	if not held_cards[2]:
		$Card2.texture = load("res://assets/cards/"+ h[2].get_card_image())
		await $FlipTimer.timeout
	if not held_cards[3]:
		$Card3.texture = load("res://assets/cards/"+ h[3].get_card_image())
		await $FlipTimer.timeout
	if not held_cards[4]:
		$Card4.texture = load("res://assets/cards/"+ h[4].get_card_image())
		await $FlipTimer.timeout
		
#	$Card2.texture = load("res://assets/cards/"+ h[2].get_card_image())
#	await $FlipTimer.timeout
#	$Card3.texture = load("res://assets/cards/"+ h[3].get_card_image())
#	await $FlipTimer.timeout
#	$Card4.texture = load("res://assets/cards/"+ h[4].get_card_image())
	#$FlipTimer.stop()
	
func show_card_backs():
	#$FlipTimer.start()
	
	if not held_cards[0]:
		$Card0.texture = load("res://assets/cards/" + card_back_color)
		await $FlipTimer.timeout
	if not held_cards[1]:
		$Card1.texture = load("res://assets/cards/" + card_back_color)
		await $FlipTimer.timeout
	if not held_cards[2]:
		$Card2.texture = load("res://assets/cards/" + card_back_color)
		await $FlipTimer.timeout
	if not held_cards[3]:
		$Card3.texture = load("res://assets/cards/" + card_back_color)
		await $FlipTimer.timeout
	if not held_cards[4]:
		$Card4.texture = load("res://assets/cards/" + card_back_color)
		await $FlipTimer.timeout
		
#	$Card0.texture = load("res://assets/cards/" + card_back_color)
#	await $FlipTimer.timeout
#	$Card1.texture = load("res://assets/cards/" + card_back_color)
#	await $FlipTimer.timeout
#	$Card2.texture = load("res://assets/cards/" + card_back_color)
#	await $FlipTimer.timeout
#	$Card3.texture = load("res://assets/cards/" + card_back_color)
#	await $FlipTimer.timeout
#	$Card4.texture = load("res://assets/cards/" + card_back_color)
	#$FlipTimer.stop()	
	
func open_fresh_deck(): # Should only run once.
	#print('Opening a fresh deck of cards.')
	for x in range(4):
		for y in range(13):
			card = Card.new(values[y],suits[x])
			fresh_deck.append(card)
# -------------------	
	
func shuffle_deck():
	#print('Shuffling deck ...')
	deck.clear()
	for i in range(52):
		deck.append(fresh_deck[i])
	deck.shuffle()
	
func clear_held_cards():
#	print('Clearing held cards.')
	held_cards = [false, false, false, false, false]
	show_held_labels(held_cards)
	
func deal_hand(): # 
	print('Bet: $' + str(bet_amt))
	for i in range(5):
		dealt_hand.append(deck[i])
		draw_hand.append(deck[i+5])
	print("Dealt hand:  ",dealt_hand[0].get_card_name() + ' ', dealt_hand[1].get_card_name() + ' ',
	dealt_hand[2].get_card_name() + ' ', dealt_hand[3].get_card_name() + ' ', dealt_hand[4].get_card_name())
	print("Draw hand:   ",draw_hand[0].get_card_name() + ' ', draw_hand[1].get_card_name() + ' ',
	draw_hand[2].get_card_name() + ' ', draw_hand[3].get_card_name() + ' ', draw_hand[4].get_card_name())
	
func draw_cards():
	for i in range(5):
		if !held_cards[i]:
			dealt_hand[i] = draw_hand[i]
	final_hand = dealt_hand.duplicate(true)
	#dealt_hand.clear() 
	# THIS CAUSED A NASTY ERROR when using SPACEBAR to 'draw'
	# but only after using the Deal/Draw button beore it.
	
#	print('===== rigged hand ======')
#	hand_values=[10,11,12,13,14]
#	hand_suits=['h','h','h','h','h']
#	for i in range(5):
#		final_hand[i].value = hand_values[i]
#		final_hand[i].suit = hand_suits[i]
	
	print("Final hand:  ",final_hand[0].get_card_name() + ' ', final_hand[1].get_card_name() + ' ',
	final_hand[2].get_card_name() + ' ', final_hand[3].get_card_name() + ' ', final_hand[4].get_card_name())
#	print(hand_name + 'line 238 -- draw_cards()')
#	print("line 239 Hands played: " + str(hands_played) + "\n")
	
func update_credits():
	if credits < 1:
		credits = 0
	$UI/Control/CreditLabel.text = "CREDIT  $" + str(credits)
	#$UI/Control/HandsLabel.text = "HANDS  " + str(hands_played)
	
func show_held_cards():
	print(held_cards)
	
func show_held_labels(hc):
	# If I put these in an HBox, they line up perfectly ...
	# ... as long as they're ALL visible! If any are NOT ...
	# ... visible, the alignment turns to shit.
	$UI/Control/Held1Label.visible = hc[0]
	$UI/Control/Held2Label.visible = hc[1]
	$UI/Control/Held3Label.visible = hc[2]
	$UI/Control/Held4Label.visible = hc[3]
	$UI/Control/Held5Label.visible = hc[4]
	
func evaluate_final_hand(fh):
	hand_values.clear()
	hand_suits.clear()
	for i in range(5):
		hand_values.append(fh[i].value)
		hand_suits.append(fh[i].suit)
	hand_values.sort()
	hand_suits.sort()
	#print(hand_values, hand_suits)
	win_amt = 0
	
	# -------- winning hands -----
	fl = is_flush(hand_suits)
	st = is_straight(hand_values)
		
	if is_roy_flush(hand_values): # royal flush
		$WinSound.stream = preload("res://assets/BusyCity.mp3")
		$WinSound.play()
		$WinSound.play()
		if bet_amt < 5:
			win_amt = bet_amt * 250
			payout_signal.emit(win_amt)
		else:
			win_amt = bet_amt * 800
			payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'ROYAL FLUSH'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel0.set("theme_override_colors/font_color", Color(1,1,1))
		return
	
	if is_str_flush(): # straight flush
		$WinSound.stream = preload("res://assets/win6.mp3")
		$WinSound.play()
		win_amt = bet_amt * 50
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'STRAIGHT FLUSH'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel6.set("theme_override_colors/font_color", Color(1,1,1))
		return
	
	if is_foak(hand_values): # four of a kind
		$WinSound.stream = preload("res://assets/win3.mp3")
		$WinSound.play()
		win_amt = bet_amt * 25
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'FOUR OF A KIND'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel12.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if is_full(hand_values): # full house
		$WinSound.stream = preload("res://assets/win2.mp3")
		$WinSound.play()
		win_amt = bet_amt * 9
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'FULL HOUSE'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel18.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if fl:						# flush
		$WinSound.stream = preload("res://assets/short_win.mp3")
		$WinSound.play()
		win_amt = bet_amt * 6
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'FLUSH'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel24.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if st:						# straight
		$WinSound.stream = preload("res://assets/short_win.mp3")
		$WinSound.play()
		win_amt = bet_amt * 4
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'STRAIGHT'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel30.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if is_toak(hand_values):	# three of a kind
		$WinSound.stream = preload("res://assets/short_win.mp3")
		$WinSound.play()
		win_amt = bet_amt * 3
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'THREE OF A KIND'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel36.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if is_two_pair(hand_values):	# two pair
		$WinSound.stream = preload("res://assets/short_win.mp3")
		$WinSound.play()
		win_amt = bet_amt * 2
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'TWO PAIR'
		$UI/Control/WinHandLabel. text = hand_name
		$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel42.set("theme_override_colors/font_color", Color(1,1,1))
		return
		
	if is_job(hand_values):	# jacks or better
		$WinSound.stream = preload("res://assets/short_win.mp3")
		$WinSound.play()
		win_amt = bet_amt
		payout_signal.emit(win_amt)
		credits += win_amt
		hand_name = 'JACKS OR BETTER'
		#$UI/Control/WinHandLabel. text = hand_name
		#$UI/Control/WinAmtLabel. text = 'WIN  ' + str(win_amt)
		$UI/Control/PayTableGrid/TableLabel48.set("theme_override_colors/font_color", Color(1,1,1)) # this works!
		return
	
	hand_name = '' # nothing
	$UI/Control/WinHandLabel. text = hand_name
	#$WinSound.play()
	#$UI/Control/PayTableGrid/TableLabel48.set("theme_override_colors/font_color",null)
	return
	
	
	
func is_job(hv) -> bool:
	if hv[0] == hv[1] and hv[1] >= 11: return true
	if hv[1] == hv[2] and hv[2] >= 11: return true
	if hv[2] == hv[3] and hv[3] >= 11: return true
	if hv[3] == hv[4] and hv[4] >= 11: return true
	return false
	
func is_two_pair(hv) -> bool:
	if hv[0] == hv[1] and hv[2] == hv[3]: return true
	if hv[0] == hv[1] and hv[3] == hv[4]: return true
	if hv[1] == hv[2] and hv[3] == hv[4]: return true
	return false
	
func is_toak(hv) -> bool:
	if hv[0] == hv[1] and hv[1] == hv[2]: return true
	if hv[1] == hv[2] and hv[2] == hv[3]: return true
	if hv[2] == hv[3] and hv[3] == hv[4]: return true
	return false
	
func is_straight(hv) -> bool:
	if hv[0] + 1 == hv[1] and hv[1] + 1 == hv[2] and hv[2] + 1 == hv[3] and hv[3] + 1 == hv[4]:
		return true
	
	if hv[0] == 2 and hv[1] == 3 and hv[2] == 4 and hv[3] == 5 and hv[4] == 14: return true
	return false

func is_flush(hs):
#	if hs[0] == hs[1] and hs[1] == hs[2] \
#	and hs[2] == hs[3] and hs[3] == hs[4]: return true
	if hs[0] == hs[4]: return true
	return false
	
func is_full(hv) -> bool:
	if hv[0] == hv[1] and hv[2] == hv[3] and hv[3] == hv[4]: return true
	if hv[3] == hv[4] and hv[0] == hv[1] and hv[1] == hv[2]: return true
	return false
	
func is_foak(hv) -> bool:
	if hv[1] == hv[2] and hv[2] == hv[3] and (hv[0] == hv[2] or hv[4] == hv[2]): return true
	return false
	
func is_str_flush() -> bool:
	if st and fl: return true
	return false
	
func is_roy_flush(hv) -> bool:
	if st and fl and hv[0] == 10: return true
	return false
		
func game_over():
	print("Game Over!")
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()
