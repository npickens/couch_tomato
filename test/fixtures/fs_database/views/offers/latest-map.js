function(doc) {
  if (doc.active) {
    date = doc.last_revision;
    emit(doc.publisher_nickname, null);
    // emit(doc.publisher_nickname, {
    //    "_id": doc['_id'],
    //    "_rev": doc['_rev'],
    //    "state": doc.state,
    //    "commission": doc.commission[date],
    //    "created_on": doc.created_on,
    //    "title": doc.title,
    //    "gravity": doc.gravity[date],
    //    "total_earnings_per_sale": doc.total_earnings_per_sale[date],
    //    "earned_per_sale": doc.earned_per_sale[date],
    //    "recurring_products": doc.recurring_products[date],
    //    "description": doc.description,
    //    "categories": doc.categories,
    //    "publisher_nickname": doc.publisher_nickname,
    //    "percent_per_sale": doc.percent_per_sale[date],
    //    "total_rebill_amt": doc.total_rebill_amt[date],
    //    "referred": doc.referred[date],
    //    "newness_score": doc.newness_score,
    //    "gravity_score": doc.gravity_score,
    //    "popularity_score": doc.popularity_score
    // });
  }
}