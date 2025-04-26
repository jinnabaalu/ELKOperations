# Logstash with Drop | Mutate | 

Run the Elasticsearch and Kibana with the following command to save student data into the index

```bash
chmod +x init.sh
```

Run the Logstash 



## Ingest Node Pipeline

### Difference Between Indexing and Ingest Indexing

- POST a Simple document into a book index with type data
```
curl -XPOST http://localhost:9200/book/data?pretty -H "Content-Type: application/json" -d @book.json
```
- Get docs from book index

Check with the field description, without pipeline

```
curl -s -XGET http://localhost:9200/book/_search?pretty=true
```
- Create Ingest Pipeline
```
curl -s -H 'Content-Type: application/json' -XPUT http://localhost:9200/_ingest/pipeline/book-pipeline?pretty -d @book-pipeline.json
```
- Post the Index with Pipeline

While posting the document into  index we use an extra query parameter `pipeline=book-pipeline`

```
curl -s -H 'Content-Type: application/json' -XPOST http://localhost:9200/book/data?pipeline=book-pipeline -d @book.json
```
- Get the docs

Verify the `description` property is missing in one of the document

```
curl -s -XGET http://localhost:9200/book/data/_search?pretty=true
```

We can implement above steps with one Simulation API all in one go as follows

### Simulation API

- Post a document with the same pipeline with `_simulate`
```
curl -H 'Content-Type: application/json' -XPOST http://localhost:9200/_ingest/pipeline/_simulate?pretty=true -d @simulate-book.json

```
Check with the response document, we'll see the description field is removed
