#!/usr/bin/ruby
#!/usr/bin/ruby -rdebug
# -*- coding: utf-8 -*- 
#
# 2048.rb - 2048 Game
# $ ./2048.rb
#   or
# $ irb
# irb> load("2048.rb")
# irb> main
#
# 2019/04/28 Rubyに移植開始
# 2019/05/03 Rubyに移植完了

require 'optparse'

$auto_mode = 4           # 読みの深さ(>0)
$calc_gap_mode = 0       # gap計算モード(0:normal 1:端の方が小さければ+1 2:*2 3:+大きい方の値 4:+大きい方の値/10 5:+両方の値)
$print_mode = 100        # 途中経過の表示間隔(0：表示しない)
$print_mode_turbo = 1    # 0:PRINT_MODEに従う 1:TURBO_MINUS_SCOREを超えたら強制表示 2:TURBO_PLUS_SCOREを超えたら強制表示
$pause_mode = 0          # 終了時に一時中断(0/1)
$one_time = 1            # 繰り返し回数
$seed = 1                # 乱数の種
$turbo_minus_percent       = 55      # 空き率がこれ以上であれば読みの深さを下げる
$turbo_minus_percent_level = 1       # 下げる読みの深さ
$turbo_minus_score         = 20000   # 点数がこれ以下であれば読みの深さを下げる
$turbo_minus_score_level   = 1       # 下げる読みの深さ
$turbo_plus_percent        = 10      # 空き率がこれ以下であれば読みの深さを上げる
$turbo_plus_percent_level  = 1       # 上げる読みの深さ
$turbo_plus_score          = 200000  # 点数がこれ以上であれば読みの深さを上げる
$turbo_plus_score_level    = 1       # 上げる読みの深さ

D_BONUS = 10
D_BONUS_USE_MAX = true #10固定ではなく最大値とする
GAP_EQUAL = 0

INIT2 = 1
INIT4 = 2
RNDMAX = 4
GAP_MAX = 100000000.0
XMAX = 4
YMAX = 4
XMAX_1 = (XMAX-1)
YMAX_1 = (YMAX-1)

$board = Array.new(YMAX).map{Array.new(XMAX)}
$sp = 0

$pos_x = Array.new(XMAX*YMAX)
$pos_y = Array.new(XMAX*YMAX)
$pos_val = Array.new(XMAX*YMAX)
$score = 0
$gen = 0
$count_2 = 0
$count_4 = 0
$count_calcGap = 0
$count_getGap = 0

$start_time = Time.now
$last_time = Time.now
$total_start_time = Time.now
$total_last_time = Time.now

$count = 1
$sum_score = 0
$max_score = 0
$max_seed = 0
$min_score = (GAP_MAX)
$min_seed = 0
$ticks_per_sec = 1

def main()
    opt = OptionParser.new
    opt.on('--auto_mode VAL') {|v| $auto_mode = v.to_i}
    opt.on('--calc_gap_mode VAL') {|v| $calc_gap_mode = v.to_i}
    opt.on('--print_mode VAL') {|v| $print_mode = v.to_i}
    opt.on('--print_mode_turbo VAL') {|v| $print_mode_turbo = v.to_i}
    opt.on('--pause_mode VAL') {|v| $pause_mode = v.to_i}
    opt.on('--one_time VAL') {|v| $one_time = v.to_i}
    opt.on('--seed VAL') {|v| $seed = v.to_i}
    opt.on('--turbo_minus_percent VAL') {|v| $turbo_minus_percent = v.to_i}
    opt.on('--turbo_minus_percent_level VAL') {|v| $turbo_minus_percent_level = v.to_i}
    opt.on('--turbo_minus_score VAL') {|v| $turbo_minus_score = v.to_i}
    opt.on('--turbo_minus_score_level VAL') {|v| $turbo_minus_score_level = v.to_i}
    opt.on('--turbo_plus_percent VAL') {|v| $turbo_plus_percent = v.to_i}
    opt.on('--turbo_plus_percent_level VAL') {|v| $turbo_plus_percent_level = v.to_i}
    opt.on('--turbo_plus_score VAL') {|v| $turbo_plus_score = v.to_i}
    opt.on('--turbo_plus_score_level VAL') {|v| $turbo_plus_score_level = v.to_i}
    opt.parse!(ARGV)
	printf("$auto_mode=%d\n", $auto_mode)
	printf("$calc_gap_mode=%d\n", $calc_gap_mode)
	printf("$print_mode=%d\n", $print_mode)
	printf("$print_mode_turbo=%d\n", $print_mode_turbo)
	printf("$pause_mode=%d\n", $pause_mode)
	printf("$seed=%d\n", $seed)
	printf("$one_time=%d\n", $one_time)
	printf("$turbo_minus_percent=%d\n", $turbo_minus_percent)
	printf("$turbo_minus_percent_level=%d\n", $turbo_minus_percent_level)
	printf("$turbo_minus_score=%d\n", $turbo_minus_score)
	printf("$turbo_minus_score_level=%d\n", $turbo_minus_score_level)
	printf("$turbo_plus_percent=%d\n", $turbo_plus_percent)
	printf("$turbo_plus_percent_level=%d\n", $turbo_plus_percent_level)
	printf("$turbo_plus_score=%d\n", $turbo_plus_score)
	printf("$turbo_plus_score_level=%d\n", $turbo_plus_score_level)

	if ($seed > 0)
		srand($seed)
	else
		srand(Time.now)
	end
	$total_start_time = Time.now
	init_game
	while true
		gap = moveAuto($auto_mode)
		$gen += 1
		appear
		disp(gap, $print_mode > 0 &&
			(($gen%$print_mode)==0 ||
				($print_mode_turbo==1 && $score>$turbo_minus_score) ||
				($print_mode_turbo==2 && $score>$turbo_plus_score)))
		if isGameOver
			sc = getScore
			$sum_score += sc
			if (sc > $max_score)
				$max_score = sc
				$max_seed = $seed
			end
			if (sc < $min_score)
				$min_score = sc
				$min_seed = $seed
			end
			printf("Game Over! (level=%d seed=%d) %s #%d Ave.=%d Max=%d(seed=%d) Min=%d(seed=%d)\ngetGap=%d calcGap=%d %.1f,%.1f %d%%,%d %d,%d %d%%,%d %d,%d %d $calc_gap_mode=%d\n",
				$auto_mode, $seed,
				getTime, $count, $sum_score/$count,
				$max_score, $max_seed, $min_score, $min_seed,
				$count_getGap, $count_calcGap,
				(D_BONUS),(GAP_EQUAL),
				$turbo_minus_percent, $turbo_minus_percent_level,
				$turbo_minus_score, $turbo_minus_score_level,
				$turbo_plus_percent, $turbo_plus_percent_level,
				$turbo_plus_score, $turbo_plus_score_level,
				$print_mode_turbo, $calc_gap_mode)
			disp(gap, true)
			if ($one_time > 0) then
				$one_time -= 1
				if ($one_time == 0) then
					break
				end
			end
			if ($pause_mode > 0)
				if (getc == 'q')
					break
				end
			end
			$seed += 1
			srand($seed)
			init_game
			$count += 1
		end
	end
	$total_last_time = Time.now
	printf("Total time = %.1f (sec)\n",($total_last_time-$total_start_time)/$ticks_per_sec)
end

def getCell(x, y)
	return ($board[x][y])
end

def setCell(x, y, n)
	$board[x][y] = (n)
	return (n)
end

def clearCell(x, y)
	setCell(x, y, 0)
end

def copyCell(x1, y1, x2, y2)
	return (setCell(x2, y2, getCell(x1, y1)))
end

def moveCell(x1, y1, x2, y2)
	copyCell(x1, y1, x2, y2)
	clearCell(x1, y1)
end

def addCell(x1, y1, x2, y2)
	setCell(x2, y2, getCell(x1, y1) + 1)
	clearCell(x1, y1)
	if ($sp < 1)
		addScore(1 << (getCell(x2, y2)))
	end
end

def isEmpty(x, y)
	return (getCell(x, y) == 0)
end

def isNotEmpty(x, y)
	return (!isEmpty(x, y))
end

def isGameOver()
	if (ret,_a,_b = isMovable;ret)
		return false
	else
		return true
	end
end

def getScore()
	return $score
end

def setScore(sc)
	$score = (sc)
	return $score
end

def addScore(sc)
	$score += (sc)
	return $score
end

def clear()
	for y in 0..YMAX_1
		for x in 0..XMAX_1
			clearCell(x, y)
		end
	end
end

def disp(gap, debug)
	now = Time.now
	if ($count == 0)
		printf("[%d:%d] %d (%.2f/%.1f sec) %.6f %s seed=%d 2=%.2f%%\r", $count, $gen, getScore,(now-$last_time)/$ticks_per_sec,(now-$start_time)/$ticks_per_sec, gap, getTime, $seed, ($count_2.to_f)/($count_2+$count_4)*100)
	else
		printf("[%d:%d] %d (%.2f/%.1f sec) %.6f %s seed=%d 2=%.2f%% Ave.=%d\r", $count, $gen, getScore,(now-$last_time)/$ticks_per_sec,(now-$start_time)/$ticks_per_sec, gap, getTime, $seed, ($count_2.to_f)/($count_2+$count_4)*100, ($sum_score+getScore)/$count)
	end
	$last_time = now
	if (debug)
		printf("\n")
		for y in 0..YMAX_1
			for x in 0..XMAX_1
				v = getCell(x, y)
				if (v > 0)
					printf("%5d ", 1<<(v))
				else
					printf("%5s ", ".")
				end
			end
			printf("\n")
		end
	end
end

def init_game()
	$gen = 1
	$count_2 = 0
	$count_4 = 0
	$count_calcGap = 0
	$count_getGap = 0
	$start_time = Time.now
	$last_time = $start_time
	setScore(0)
	clear
	appear
	appear
	disp(0.0, $print_mode == 1)
end

def getTime()
	return Time.now.strftime("%Y/%m/%d %H:%M:%S")
end

def appear()
	n = 0
	for y in 0..YMAX_1
		for x in 0..XMAX_1
			if (isEmpty(x, y))
				$pos_x[n] = x
				$pos_y[n] = y
				n += 1
			end
		end
	end
	if (n> 0)
		v = 0
		i = rand(65535) % n
		if ((rand(65535) % RNDMAX) >= 1)
			v = INIT2
			$count_2 += 1
		else
			v = INIT4
			$count_4 += 1
		end
		x = $pos_x[i]
		y = $pos_y[i]
		setCell(x, y, v)
		return true
	end
	return false
end

def countEmpty()
	ret = 0
	for y in 0..YMAX_1
		for x in 0..XMAX_1
			if (isEmpty(x, y))
				ret += 1
			end
		end
	end
	return ret
end

def move_up()
	move = 0
	yLimit = 0
	yNext = 0
	for x in 0..XMAX_1
		yLimit = 0
		for y in 1..YMAX_1
			if (isNotEmpty(x, y))
				yNext = y - 1
				while yNext >= yLimit
					if (isNotEmpty(x, yNext))
						break
					end
					if (yNext == 0)
						break
					end
					yNext = yNext - 1
				end
				if (yNext < yLimit)
					yNext = yLimit
				end
				if (isEmpty(x, yNext))
					moveCell(x, y, x, yNext)
					move += 1
				else
					if (getCell(x, yNext) == getCell(x, y))
						addCell(x, y, x, yNext)
						move += 1
						yLimit = yNext + 1
					else
						if (yNext+1 != y)
							moveCell(x, y, x, yNext+1)
							move += 1
							yLimit = yNext + 1
						end
					end
				end
			end
		end
	end
	return move
end

def move_left()
	move = 0
	xLimit = 0
	xNext = 0
	for y in 0..YMAX_1
		xLimit = 0
		for x in 1..XMAX_1
			if (isNotEmpty(x, y))
				xNext = x - 1
				while xNext >= xLimit
					if (isNotEmpty(xNext, y))
						break
					end
					if (xNext == 0)
						break
					end
					xNext = xNext - 1
				end
				if (xNext < xLimit)
					xNext = xLimit
				end
				if (isEmpty(xNext, y))
					moveCell(x, y, xNext, y)
					move += 1
				else
					if (getCell(xNext, y) == getCell(x, y))
						addCell(x, y, xNext, y)
						move += 1
						xLimit = xNext + 1
					else
						if (xNext+1 != x)
							moveCell(x, y, xNext+1, y)
							move += 1
							xLimit = xNext + 1
						end
					end
				end
			end
		end
	end
	return move
end

def move_down()
	move = 0
	yLimit = 0
	yNext = 0
	for x in 0..XMAX_1
		yLimit = YMAX_1
        (YMAX - 2).downto(0) do |y|
			if (isNotEmpty(x, y))
				yNext = y + 1
				while yNext <= yLimit
					if (isNotEmpty(x, yNext))
						break
					end
					if (yNext == YMAX_1)
						break
					end
					yNext = yNext + 1
				end
				if (yNext > yLimit)
					yNext = yLimit
				end
				if (isEmpty(x, yNext))
					moveCell(x, y, x, yNext)
					move += 1
				else
					if (getCell(x, yNext) == getCell(x, y))
						addCell(x, y, x, yNext)
						move += 1
						yLimit = yNext - 1
					else
						if (yNext-1 != y)
							moveCell(x, y, x, yNext-1)
							move += 1
							yLimit = yNext - 1
						end
					end
				end
			end
		end
	end
	return move
end

def move_right()
	move = 0
	xLimit = 0
	xNext = 0
	for y in 0..YMAX_1
		xLimit = XMAX_1
        (XMAX - 2).downto(0) do |x|
			if (isNotEmpty(x, y))
				xNext = x + 1
				while xNext <= xLimit
					if (isNotEmpty(xNext, y))
						break
					end
					if (xNext == XMAX_1)
						break
					end
					xNext = xNext + 1
				end
				if (xNext > xLimit)
					xNext = xLimit
				end
				if (isEmpty(xNext, y))
					moveCell(x, y, xNext, y)
					move += 1
				else
					if (getCell(xNext, y) == getCell(x, y))
						addCell(x, y, xNext, y)
						move += 1
						xLimit = xNext - 1
					else
						if (xNext-1 != x)
							moveCell(x, y, xNext-1, y)
							move += 1
							xLimit = xNext - 1
						end
					end
				end
			end
		end
	end
	return move
end

def moveAuto(autoMode)
	empty = countEmpty
	sc = getScore
	if (empty >= XMAX*YMAX*$turbo_minus_percent.to_f/100)
		autoMode -= $turbo_minus_percent_level
	elsif (empty < XMAX*YMAX*$turbo_plus_percent.to_f/100)
		autoMode += $turbo_plus_percent_level
	end
	if (sc < $turbo_minus_score)
		autoMode -= $turbo_minus_score_level
	elsif (sc >= $turbo_plus_score)
		autoMode += $turbo_plus_score_level
	end
	return moveBest(autoMode, true)
end

def dup_board(board)
    ret = Array.new(board)
    for n in 0..XMAX_1
        ret[n] = Array.new(board[n])
    end
    return ret
end

def copy_board(src, dst)
    for y in 0..YMAX_1
        for x in 0..XMAX_1
            dst[x][y] = src[x][y]
        end
    end
end

def moveBest(nAutoMode, move)
	nGap = 0
	nGapBest = 0
	nDirBest = 0
	nDir = 0
	board_bak = dup_board($board)
	$sp += 1
	nGapBest = GAP_MAX
	if (move_up > 0)
		nDir = 1
		nGap = getGap(nAutoMode, nGapBest)
		if (nGap < nGapBest)
			nGapBest = nGap
			nDirBest = 1
		end
	end
	copy_board(board_bak, $board)
	if (move_left > 0)
		nDir = 2
		nGap = getGap(nAutoMode, nGapBest)
		if (nGap < nGapBest)
			nGapBest = nGap
			nDirBest = 2
		end
	end
	copy_board(board_bak, $board)
	if (move_down > 0)
		nDir = 3
		nGap = getGap(nAutoMode, nGapBest)
		if (nGap < nGapBest)
			nGapBest = nGap
			nDirBest = 3
		end
	end
	copy_board(board_bak, $board)
	if (move_right > 0)
		nDir = 4
		nGap = getGap(nAutoMode, nGapBest)
		if (nGap < nGapBest)
			nGapBest = nGap
			nDirBest = 4
		end
	end
	copy_board(board_bak, $board)
	$sp -= 1
	if (move)
		if (nDirBest == 0)
			printf("\n***** Give UP *****\n")
			nDirBest = nDir
		end
		case 
		when nDirBest == 1
			move_up
		when nDirBest == 2
			move_left
		when nDirBest == 3
			move_down
		when nDirBest == 4
			move_right
		end
	end
	return nGapBest
end

def getGap(nAutoMode, nGapBest)
	$count_getGap += 1
	ret = 0.0
	movable, nEmpty, nBonus = isMovable
	if (! movable)
		ret = GAP_MAX
	elsif (nAutoMode <= 1)
		ret = getGap1(nGapBest, nEmpty, nBonus)
	else
		alpha = nGapBest *(nEmpty) #累積がこれを超えれば、平均してもnGapBestを超えるので即枝刈りする
		for x in 0..XMAX_1
			for y in 0..YMAX_1
				if (isEmpty(x, y))
					setCell(x, y, INIT2)
					ret += moveBest(nAutoMode-1, false) * (RNDMAX - 1) / RNDMAX
					if (ret >= alpha)
						return GAP_MAX	#枝刈り
					end
					setCell(x, y, INIT4)
					ret += moveBest(nAutoMode-1, false) / RNDMAX
					if (ret >= alpha)
						return GAP_MAX	#枝刈り
					end
					clearCell(x, y)
				end
			end
		end
		ret /=(nEmpty) #平均値を返す
	end
	return ret
end

def getGap1(nGapBest, nEmpty, nBonus)
	ret = 0.0
	ret_appear = 0.0
	alpha = nGapBest * nBonus
	edgea = false
	edgeb = false
	for x in 0..XMAX_1
		for y in 0..YMAX_1
			v = getCell(x, y)
			edgea = (x == 0 || y == 0) || (x == XMAX - 1 || y == YMAX_1)
			if (v > 0)
				if (x < XMAX_1)
					x1 = getCell(x+1, y)
					edgeb = (y == 0) || (x+1 == XMAX - 1 || y == YMAX_1)
					if (x1 > 0)
						ret += calcGap(v, x1, edgea, edgeb)
					else
						ret_appear += calcGap(v, INIT2, edgea, edgeb) * (RNDMAX - 1) / RNDMAX
						ret_appear += calcGap(v, INIT4, edgea, edgeb) / RNDMAX
					end
				end
				if (y < YMAX_1)
					y1 = getCell(x, y+1)
					edgeb = (x == 0) || (x == XMAX - 1 || y+1 == YMAX_1)
					if (y1 > 0)
						ret += calcGap(v, y1, edgea, edgeb)
					else
						ret_appear += calcGap(v, INIT2, edgea, edgeb) * (RNDMAX - 1) / RNDMAX
						ret_appear += calcGap(v, INIT4, edgea, edgeb) / RNDMAX
					end
				end
			else
				if (x < XMAX_1)
					x1 = getCell(x+1, y)
					edgeb = (y == 0) || (x+1 == XMAX - 1 || y == YMAX_1)
					if (x1 > 0)
						ret_appear += calcGap(INIT2, x1, edgea, edgeb) * (RNDMAX - 1) / RNDMAX
						ret_appear += calcGap(INIT4, x1, edgea, edgeb) / RNDMAX
					end
				end
				if (y < YMAX_1)
					y1 = getCell(x, y+1)
					edgeb = (x == 0) || (x == XMAX - 1 || y+1 == YMAX_1)
					if (y1 > 0)
						ret_appear += calcGap(INIT2, y1, edgea, edgeb) * (RNDMAX - 1) / RNDMAX
						ret_appear += calcGap(INIT4, y1, edgea, edgeb) / RNDMAX
					end
				end
			end
			if (ret + ret_appear/(nEmpty) > alpha)
				return GAP_MAX
			end
		end
	end
	ret += ret_appear /(nEmpty)
	ret /= nBonus
	return ret
end

def calcGap(a, b, edgea, edgeb)
	$count_calcGap += 1
	ret = 0
	if (a > b)
		ret =(a - b)
		if ($calc_gap_mode > 0 && ! edgea && edgeb)
			case
			when $calc_gap_mode == 1
				ret += 1
			when $calc_gap_mode == 2
				ret *= 2
			when $calc_gap_mode == 3
				ret +=(a)
			when $calc_gap_mode == 4
				ret +=(a)/10
			when $calc_gap_mode == 5
				ret +=(a+b)
			end
		end
	elsif (a < b)
		ret =(b - a)
		if ($calc_gap_mode > 0 && edgea && ! edgeb)
			case
			when $calc_gap_mode == 1
				ret += 1
			when $calc_gap_mode == 2
				ret *= 2
			when $calc_gap_mode == 3
				ret +=(a)
			when $calc_gap_mode == 4
				ret +=(a)/10
			when $calc_gap_mode == 5
				ret +=(a+b)
			end
		end
	else
		ret = GAP_EQUAL
	end
	return ret
end

def isMovable()
	ret = false #動けるか？
	nEmpty = 0 #空きの数
	nBonus = 1.0 #ボーナス（隅が最大値ならD_BONUS）
	max = 0
	for y in 0..YMAX_1
		for x in 0..XMAX_1
			val = getCell(x, y)
			if (val == 0)
				ret = true
				nEmpty += 1
			else
				if (val > max)
					max = val
					max_x = x
					max_y = y
				end
				if (! ret)
					if (x < XMAX_1)
						x1 = getCell(x+1, y)
						if (val == x1 || x1 == 0)
							ret = true
						end
					end
					if (y < YMAX_1)
						y1 = getCell(x, y+1)
						if (val == y1 || y1 == 0)
							ret = true
						end
					end
				end
			end
		end
	end
	if ((max_x == 0 || max_x == XMAX_1) &&
		(max_y == 0 || max_y == YMAX_1))
		if (D_BONUS_USE_MAX)
			nBonus =(max)
		else
			nBonus = D_BONUS
		end
	end
	return ret, nEmpty, nBonus
end

main
