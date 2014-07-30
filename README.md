# Lex D

A small Sinatra service that takes a string and returns a lexical diversity score.

## Endpoint

### POST /

Send me a string and I'll give you the corresponding Lexical Diversity score.

## Research

MTLD implementation based on [McCarthy and Jarvis (2010)](http://link.springer.com/article/10.3758%2FBRM.42.2.381).

HDD implementation based on [McCarthy and Jarvis (2007)](http://ltj.sagepub.com/content/24/4/459.short?patientinform-links=yes&legid=spltj;24/4/459) and [McCarthy and Jarvis (2010)](http://link.springer.com/article/10.3758%2FBRM.42.2.381).

Yules I implementation based on the description in [this](http://swizec.com/blog/measuring-vocabulary-richness-with-python/swizec/2528) blog post by Swizec Teller.