require 'sinatra/base'

class Lex_D < Sinatra::Base

  get '/document/:id' do
    # Find document with :id


    # Pull text out of document
    text = sample_text # for now

    # Clean text
    text_array = clean_text(text)

    # Make sure array isn't empty or too short
    if (text_array.empty?)
      return "EMPTY STRING"
    elsif (text_array.length < 40)
      return "TOO SHORT"
    end

    # Run lexical diversity analysis
    score = lex_d(text_array)

    # Return score
    "#{score}"

  end




  ###################################
  # lex_d
  ###################################
  def lex_d(text_array, mtld_ttr_threshold=0.72, hdd_sample_size=40.0)
    (mtld(text_array, mtld_ttr_threshold) + hdd(text_array, hdd_sample_size) + yules_i(text_array)) / 3
  end




  ###################################
  # mtld
  ###################################
  def mtld(text_array, ttr_threshold=0.72)
    return 0 if text_array.empty?

    val1 = mtld_eval(text_array, ttr_threshold)
    val2 = mtld_eval(text_array.reverse, ttr_threshold)
    mtld_scale((val1 + val2) / 2.0)
  end

  def mtld_eval(text_array, ttr_threshold)
    current_ttr = 1.0
    current_types = 0.0
    current_tokens = 0.0
    current_words = []
    factors = 0.0

    text_array.each do |element|
      current_tokens += 1
      unless current_words.include?(element)
        current_types += 1
        current_words << element
      end

      current_ttr = current_types / current_tokens

      if current_ttr < ttr_threshold
        factors += 1
        current_ttr = 0.0
        current_types = 0.0
        current_tokens = 0.0
        current_words = []
      end
    end

    excess = 1.0 - current_ttr
    excess_val = 1.0 - ttr_threshold
    factors += excess / excess_val

    text_array.size / factors
  end

  def mtld_scale(mtld)
    ((mtld - 99.284) * 0.5554 + 100)
  end




  ###################################
  # hdd
  ###################################
  def hdd(token_array, sample_size=40.0)
    hdd_value = 0.0

    type_array = create_type_array(token_array)

    type_array.each do |element|
      contribution = 1.0 - hypergeometric(token_array.size, sample_size, token_array.count(element), 0.0)
      contribution = contribution / sample_size
      hdd_value += contribution
    end

    hdd_scale(hdd_value)
  end

  # hdd helpers
  #
  def hypergeometric(population, sample, pop_successes, samp_successes)
    (combination(pop_successes, samp_successes) * combination(population - pop_successes, sample - samp_successes)) / combination(population, sample)
  end

  def combination(n, k)
    n_minus_k = n - k
    i = n
    numerator = 1
    while i > n_minus_k && i > 0 do
      numerator *= i
      i -= 1
    end
    numerator / factorial(k)
  end

  def factorial(n)
    if n <= 1
      1
    else
      n * factorial(n - 1)
    end
  end

  def hdd_scale(hdd)
    ((hdd - 0.854) * 592.1052 + 100)
  end




  ###################################
  # yules i
  ###################################
  def yules_i(token_array)
    type_array = create_type_array(token_array)

    m1 = token_array.size
    m2 = 0.0
    freq_array = Array.new(type_array.size / 2.0, 0.0)

    type_array.each do |element|
      return 0 if token_array.count(element) >= freq_array.size
      freq_array[token_array.count(element)] += 1.0
    end

    freq_array.each_with_index do |element, index|
      m2 += (element * (index ** 2))
    end
    return 0 if (m2 - m1) == 0
    yules_scale((m1 * m1) / (m2 - m1))
  end

  def yules_scale(yules)
    ((yules - 100.793) * 0.6818 + 100)
  end




  ###################################
  # helpers
  ###################################
  def create_type_array(token_array)
    type_array = []
    token_array.each do |element|
      unless type_array.include?(element)
        type_array << element
      end
    end
    type_array
  end
    
  def clean_text(text)
    new_text = text.gsub(/<(.|\n)*?>/, ' ')
    new_text = new_text.gsub(/&nbsp;/, ' ')
    new_text = new_text.gsub(/\\n/, ' ')
    new_text = new_text.gsub(/[^a-z0-9 ]/i, '')
    new_text = new_text.downcase
    new_text.split
  end

  def sample_text
    "Dorothy lived in the midst of the great Kansas prairies, with Uncle Henry, who was a farmer, and Aunt Em, who was the farmer's wife. Their house was small, for the lumber to build it had to be carried by wagon many miles. There were four walls, a floor and a roof, which made one room; and this room contained a rusty looking cookstove, a cupboard for the dishes, a table, three or four chairs, and the beds. Uncle Henry and Aunt Em had a big bed in one corner, and Dorothy a little bed in another corner. There was no garret at all, and no cellar—except a small hole dug in the ground, called a cyclone cellar, where the family could go in case one of those great whirlwinds arose, mighty enough to crush any building in its path. It was reached by a trap door in the middle of the floor, from which a ladder led down into the small, dark hole. When Dorothy stood in the doorway and looked around, she could see nothing but the great gray prairie on every side. Not a tree nor a house broke the broad sweep of flat country that reached to the edge of the sky in all directions. The sun had baked the plowed land into a gray mass, with little cracks running through it. Even the grass was not green, for the sun had burned the tops of the long blades until they were the same gray color to be seen everywhere. Once the house had been painted, but the sun blistered the paint and the rains washed it away, and now the house was as dull and gray as everything else. When Aunt Em came there to live she was a young, pretty wife. The sun and wind had changed her, too. They had taken the sparkle from her eyes and left them a sober gray; they had taken the red from her cheeks and lips, and they were gray also. She was thin and gaunt, and never smiled now. When Dorothy, who was an orphan, first came to her, Aunt Em had been so startled by the child's laughter that she would scream and press her hand upon her heart whenever Dorothy's merry voice reached her ears; and she still looked at the little girl with wonder that she could find anything to laugh at. Uncle Henry never laughed. He worked hard from morning till night and did not know what joy was. He was gray also, from his long beard to his rough boots, and he looked stern and solemn, and rarely spoke. It was Toto that made Dorothy laugh, and saved her from growing as gray as her other surroundings. Toto was not gray; he was a little black dog, with long silky hair and small black eyes that twinkled merrily on either side of his funny, wee nose. Toto played all day long, and Dorothy played with him, and loved him dearly. Today, however, they were not playing. Uncle Henry sat upon the doorstep and looked anxiously at the sky, which was even grayer than usual. Dorothy stood in the door with Toto in her arms, and looked at the sky too. Aunt Em was washing the dishes."
  end
end  
