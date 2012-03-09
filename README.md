This is a simple ruby scraper which scrape's RAND's incident
database at http://smapp.rand.org/rwtid/search_form.php and outputs
the information of all the incidents into a csv file.

There are two versions:
1) randScraper.rb uses a single large query but may be
susceptiable to idle timeout errors.
2) randScraper2.rb uses 5 year queries to fix the issue in
the original, but may run a little slower
