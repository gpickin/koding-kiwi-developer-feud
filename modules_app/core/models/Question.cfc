component extends="quick.models.BaseEntity" table="questions" accessors="true" {

    property name="questionID" column="questionID" setter="false";
    property name="question";

    variables._key = "questionID";

    this.constraints = {
        "question": {
            required: true,
            size: "1..255"
        }
    }

    function answers(){
        return hasMany( "Answer@core", "questionID" );
    }
}