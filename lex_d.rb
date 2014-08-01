require 'sinatra/base'

class Lex_D < Sinatra::Base

  get '/' do
    erb :form
  end

  post '/' do
    # Pull text out of document
    text = params[:input]

    # Clean text
    text_array = clean_text(text)

    # Make sure array isn't empty or too short
    if (text_array.empty?)
      return [400, "EMPTY STRING"]
    elsif (text_array.length < 40)
      return [400, "TOO SHORT"]
    end

    # Run lexical diversity analysis
    score = lex_d(text_array)

    # Return score
    if !score.kind_of?(Numeric)
      [400, score]
    else
      [200, "#{score}"]
    end
  end




  ###################################
  # lex_d
  #
  def lex_d(text_array, mtld_ttr_threshold=0.72, hdd_sample_size=40.0)
    mtld_score = MTLD.new(text_array, mtld_ttr_threshold).run
    hdd_score = hdd(text_array, hdd_sample_size)
    yules_score = yules_i(text_array)

    return mtld_score if !mtld_score.kind_of?(Numeric)
    return hdd_score if !hdd_score.kind_of?(Numeric)
    return yules_score if !yules_score.kind_of?(Numeric)

    return "ZERO" if mtld_score == 0 || hdd_score == 0 || yules_score == 0
    (mtld_score + hdd_score + yules_score) / 3
  end




  ###################################
  # mtld
  #
  class MTLD
    attr_accessor :text_array, :ttr_threshold

    def initialize(text_array, ttr_threshold=0.72)
      self.text_array = text_array
      self.ttr_threshold = ttr_threshold
    end

    def run
      val1 = mtld_eval(text_array, ttr_threshold)
      val2 = mtld_eval(text_array.reverse, ttr_threshold)
      return 0 if val1 == 0 || val2 == 0
      mtld_scale((val1 + val2) / 2.0)
    end

    def mtld_eval(text_array, ttr_threshold)
      current_ttr = 1.0
      current_types = 0.0
      current_tokens = 0.0
      current_words = []
      factors = 0.0

      text_array.each do |word|
        current_tokens += 1
        unless current_words.include?(word)
          current_types += 1
          current_words << word
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

      return "DIVIDE BY ZERO" if factors == 0
      text_array.size / factors
    end

    def mtld_scale(mtld)
      ((mtld - 99.284) * 0.5554 + 100)
    end
  end




  ###################################
  # hdd
  #
  def hdd(token_array, sample_size=40.0)
    hdd_value = 0.0

    type_array = create_type_array(token_array)

    type_array.each do |word_type|
      contribution = 1.0 - hypergeometric(token_array.size, sample_size, token_array.count(word_type), 0.0)
      contribution = contribution / sample_size
      hdd_value += contribution
    end
    return 0 if hdd_value == 0
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
  #
  def yules_i(token_array)
    type_array = create_type_array(token_array)

    m1 = token_array.size
    m2 = 0.0
    freq_array = Array.new(type_array.size / 2.0, 0.0)

    type_array.each do |word_type|
      if token_array.count(word_type) >= freq_array.size
        return "'#{word_type}' USED TOO FREQUENTLY"
      end
      freq_array[token_array.count(word_type)] += 1.0
    end

    freq_array.each_with_index do |num_at_frequency, frequency|
      m2 += (num_at_frequency * (frequency ** 2))
    end
    return "DIVIDE BY ZERO" if (m2 - m1) == 0
    yules_scale((m1 * m1) / (m2 - m1))
  end

  def yules_scale(yules)
    ((yules - 100.793) * 0.6818 + 100)
  end




  ###################################
  # helpers
  #
  def create_type_array(token_array)
    type_array = []
    token_array.each do |word|
      unless type_array.include?(word)
        type_array << word
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
end
