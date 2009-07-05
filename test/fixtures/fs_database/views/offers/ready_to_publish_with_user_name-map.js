function(doc) {
  if (doc.active && doc.user_name && doc.state == 'ready') {
    emit(doc.publisher_nickname, doc.user_name);
  }
}