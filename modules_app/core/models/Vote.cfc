component extends="quick.models.BaseEntity" table="votes" accessors="true" {

    property name="voteID" column="voteID";
    property name="voterSignature";
    property name="answerID";

    variables._key = "voteID";

    this.constraints = {
        "answer": {
            required: true,
            size: "1..255"
        }
    }
}