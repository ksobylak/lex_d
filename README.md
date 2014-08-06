# Lex D

A small Sinatra service that takes a string and returns a lexical diversity score.

## Endpoint

### POST /

Send me a string (of forty or more words) and I'll give you the corresponding Lexical Diversity score.

For example:

    uri = URI('http://lex-d.herokuapp.com')
    text = document_to_be_scored  # (a string)
    response = Net::HTTP.post_form(uri, { "input" => text })
    status = response.code        # HTTP status code (as a String)
    score = response.body.to_f    # Lexical diversity score (as a Float)

Note: if the given string is invalid, the `response.code` will be 400, and the `response.body` will be a String describing the error.

## Invalid Input

`""` or `''` returns `"EMPTY STRING"`.

A non-empty string under forty words returns `"TOO SHORT"`.

If one word occurs greater than 50% of the time in the input, it will return `"'[word]' USED TOO FREQUENTLY"`.

If all the words are unique and no word is repeated, it will return `'DIVIDE BY ZERO'` (infinite lexical diversity).

If any of the individual measures evaluate to 0, it will return `'ZERO'` (this shouldn't happen, and is indicitive of a problem).

## Lexical Diversity Overview

The most basic way to measure the lexical diversity of a block of text is to divide the number of 'types' of words by the total number of word 'tokens'. This is known as type-token ratio (TTR). The problem with TTR is that it is very sensitive to text length. The longer the text, the lower the ratio. As more tokens are added, the number of new types continually drops and the ratio falls accordingly. A more meaningful measure for lexical diversity is highly desirable amongst language researchers, so over the years, several measures have been developed with the priority of decreasing the sensitivity to text length. The lexical diversity score returned by this service is a combination of three of these measures: the Measure of Textual Lexical Diversity (MTLD), the Hypergeometric Distribution D (HD-D) based on vocd-D, and Yule's I (the inverse of Yule's Characteristic K). The three measures are computed individually, and then scaled and averaged based on means and standard deviations computed when applied to several thousand documents in the [Scripted.com](http://www.scripted.com) database. The mean of the final measure should lie somewhere around 100, though it may be lower in general, and the standard deviation should be around 15.

### MTLD

MTLD runs through the text one word at a time and continually computes the current TTR. As more words are added, the TTR drops. Once the current TTR is below a certain threshold (0.72 in this case), a counter (called factors) increases by one and the current TTR resets. The measure then starts over on the rest of the string until the threshold has been passed again. Once the end of the text is reached, a partial factor is computed based on the distance of the current TTR to the threshold and added to the total factor count. Finally, the result is computed as the number of total words divided by the number of factors. Because there is a slight dependence on the order of the words in the text, the score is computed twice, once moving forwards and once backwards, and the ultimate result is the average of these two scores.

### HD-D

HD-D determines the overall contribution of each type of word in the text. For example, if 'the' appears 5 times, and 'a' appears 4, 'the' will have a lower contribution to the overall diversity of the text. To compute these contributions for each word, the probability of each word appearing in every possible sampling of a given sample size (40 words in this case) in the text is computed using the [hypergeometric distribution](http://en.wikipedia.org/wiki/Hypergeometric_distribution). To determine the probabilities of finding the word any number of times, the probability of not finding it is computed and subtracted from one. The contribution of each word is divided by the sample size (40) and then summed to compute the final value. 

### Yule's I

Yule's I is much more of a straight formula: `(M1 * M1) / (M2 - M1)` where `M1` equals the total number of word tokens in the text. `M2` is a bit more complicated. It consists of the sum of the number of words that occur at any frequency times that frequency squared. So for example, if 2 words occured 3 times and 5 words occured 6 times, `M2` would be `(2 * 3^2) + (5 * 6^2) = 198`.

## Research

MTLD implementation based on [McCarthy and Jarvis (2010)](http://link.springer.com/article/10.3758%2FBRM.42.2.381).

HD-D implementation based on [McCarthy and Jarvis (2007)](http://ltj.sagepub.com/content/24/4/459.short?patientinform-links=yes&legid=spltj;24/4/459) and [McCarthy and Jarvis (2010)](http://link.springer.com/article/10.3758%2FBRM.42.2.381).

Yules I implementation based on the description in [this](http://swizec.com/blog/measuring-vocabulary-richness-with-python/swizec/2528) blog post by Swizec Teller.