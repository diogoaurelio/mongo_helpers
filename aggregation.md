# Aggregation notes



// Aggregation in Node - GroupBy Example 1)
use agg
db.products.aggregate( [ { "$group": { "_id": $manufacturer, num_products: { $sum: 1} } } ])
/* result:
{ "_id": "Amazon", "num_products": 2 }
{ "_id": "Apple", "num_products": 5 }
...
*/
/*
Aggregation Pipeline - main stages
$project - reshape - 1 : 1
$match - filter - n : 1
$group - aggregate - n : 1
$sort - sort - 1 : 1
$skip - skips - n : 1
$limit - limits - n : 1
$unwind - normalize - 1 : n
$out - output - 1 : 1

*/

// Compounding grupping - GroupingBy example 2) (several groups)
use agg
db.products.aggregate( [ { "$group": { "_id": { "manufacturer":"$manufacturer", "category":"$category"}, "num_products": { "$sum": 1 } }} ])

/* result:
{ "_id": { "manufacturer": "Amazon", "category": "laptops"}, "num_products": 2 }
{ "_id": { "manufacturer": "Amazon", "category": "tablets"}, "num_products": 4 }
{ "_id": { "manufacturer": "Apple", "category": "laptops"}, "num_products": 5 }
{ "_id": { "manufacturer": "Apple", "category": "smartphones"}, "num_products": 2 }
...
*/

/*
Aggregation expressions overview - $group
$sum
$avg
$min
$max
$push
$addToSet
$first
$last
*/
//sum
use agg
db.products.aggregate( [ { "$group": { "_id": { "maker": "$manufacturer"}, "sum_prices": { "$sum": "$price"}}} ])
db.zips.aggregate( [ { "$group": { "_id": "$state", "population": { "$sum": "$pop"}}} ])
//avg
use agg
db.products.aggregate( [ { "$group": { "_id": { "maker": "$manufacturer"}, "avg_price": { "$avg": "$price"}}} ])

//enron dataset - the next is WRONG:
db.messages.aggregate( [ { $group: { "headers": { "From": "andrew.fastow@enron.com",  "To": "john.lavorato@enron.com", "count": { "$sum": 1 } }}} ])

db.messages.find( { "headers.From": "andrew.fastow@enron.com", "headers.To": "jeff.skilling@enron.com"}).count()

db.messages.aggregate([
  {
		$unwind: "$headers.To"
	},
	{
		$project: {
			"_id": 1,
			"headers.From": 1,
			"headers.To": 1
		}
	},
  { "$group" : {
   _id: { id: "$_id", from: "$headers.From", to: "$headers.To" },
		count: { $sum: 1 }
   }
 }
])


  db.messages.aggregate([
    {
  		$unwind: "$headers.To"
  	},
  	{
  		$project: {
  			"_id": 1,
  			"headers.From": 1,
  			"headers.To": 1
  		}
  	},
  	{
  		$group: {
  			_id: { id: "$_id", from: "$headers.From", to: "$headers.To" },
  			count: { $sum: 1 }
  		}
  	},
  	{
  		$group: {
  			_id: { from: "$_id.from", to: "$_id.to" },
  			count: { $sum: 1 }
  		}
  	},
  	{
  		$sort: {
  			count: -1
  		}
  	},
  	{
  		$limit: 5
  	}
  ])

  db.messages.update(
    {'headers.Message-ID': '<8147308.1075851042335.JavaMail.evans@thyme>'},
  	{$addToSet: {
  		"headers.To": "mrpotatohead@mongodb.com"
  	}},
  	{multi: true}
  )








//addToSet //note: no parallel to sql for this aggregation exp; NOTE: addToSet makes sure a label is added ONLY ONCE to array (unlike push)
use agg
db.products.aggregate( [ { "$group": { "_id": { "maker": "$manufacturer"}, "categories": { "$addToSet": "$category"}}} ])

//push // NOTE: push adds repeated values
use agg
db.products.aggregate( [ { "$group": { "_id": { "maker": "$manufacturer"}, "categories": { "$push": "$category"}}} ])

//max
use agg
db.products.aggregate( [ { "$group": { "_id": { "maker": "$manufacturer"}, "maxprice": { "$max": "$price"}}} ])

//Double grouping example
// We want to calculate the avg score per Class; and Each student has several homework grades per class;
// To calculate the Avg of grades per each class: 1) average per student per class, AND THEN avg all students per Class
db.grades.aggregate( [ { "$group": { "_id": { "class_id": "$class_id", "student_id": "$student_id"}, "average": { "$avg": "$score"} }},
                      { "$group": { "_id":"$_id.class_id", "average": { "$avg": "$average"} }}
                      ])

//Projection - enters one doc and leaves another doc, but changed; several options for transofrm: with less one key, added some value, etc.
use agg
db.grades.aggregate( [ { "$project": { "_id": 0, //zero means I don't want to specify _id key field
                                       "maker": {"$toLower": "$manufacturer"},
                                       "details": { "category": "$category", "price": {"$multiply":["$price", 10]} },
                                       "item": "$name"
                                     }

                      ])
// match = filter/find
use agg
db.zips.aggregate( [ { $match: { "state": "CA"} } ])
//combined with grouping:
db.zips.aggregate( [ { $match:
                          { "state": "CA"}
                      },
                      { $group: {
                        "_id": "$city",
                        "population": { "$sum": "$pop"},
                        "zip_codes" : { "$addToSet":"$_id"}
                        }
                      },
                      { $project: {
                          "_id": 0,
                          "city": "$_id",
                          "population": 1,
                          "zip_codes": 1
                        }
                      }
                ])

//sort + skip + limit - NOTE: sort is by default in-mem op, and limited to 100MB; it is possible to also change config to use disk;
db.zips.aggregate( [ { $match:
                          { "state": "NY"}
                      },
                      { $group: {
                        "_id": "$city",
                        "population": { "$sum": "$pop"}
                        }
                      },
                      { $project: {
                          "_id": 0,
                          "city": "$_id",
                          "population": 1
                        }
                      },
                      { $sort: {
                          "population": -1 //desc
                        }
                      }, //NOTE: ORDER DOES matter in $skip AND ONLY then $limit!!!!
                      { "$skip": 10 },
                      { "$limit": 5 }
                ])

// first and last; example: find the largest city with the largest population

db.zips.aggregate( [
                      { $group: {
                        "_id": { "state": "$state", "city": "$city" },
                        "population": { "$sum": "$pop"}
                        }
                      },
                      /* sort by state and pop */
                      { $sort: {
                          "_id.state": 1,
                          "population": -1 //desc
                        }
                      },
                      /* Group by state the cities (in each state) with biggest population, get the first item in each group */
                      { $group: {
                        "_id": "$_id.state",
                        "city": {"$first": "$_id.city" },
                        "population": { "$first": "$population"}
                        }
                      }, /* finally sort by state */
                      { $sort: { "_id": 1 } }
                ])


// unwind
{ "a": 1, "b": 4, "c": [ "apple", "banana", "orange"] }
//unwind will produce the following:
{ "a": 1, "b": 4, "c": "apple" }
{ "a": 1, "b": 4, "c":  "banana" }
{ "a": 1, "b": 4, "c": "orange" }

//Example: find out how many times a certain tag appears in each post - BLOG example
db.posts.aggregate( [
                      { "$unwind": "$tags"},
                      /* count how many times each tag appears */
                      { "$group" : {
                        "_id": "$tags",
                        "count": { "$sum": 1}
                        }
                      },
                      /* sort by popularity */
                      { "$sort": {
                          "count": -1
                        }
                      },
                      /* top 10 */
                      { "$limit": 10  },
                      /* change the name of the _id to be tag */
                      { "$project":
                        { "_id": 0,
                          "tag": "_id"
                          "count": 1
                        }
                      }

                ])

/* this generates:
{ count: 13, "tag": "sphinx"}
{ count: 11, "tag": "elephant"}
{ count: 7, "tag": "lion"}
*/

/* LIMITATIONS AGGREAGATION FRAMEWORK: 100MB for pipeline stages - unless allow option allowDiskUse
