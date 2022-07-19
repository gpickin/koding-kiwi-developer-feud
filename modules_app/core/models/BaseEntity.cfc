component extends="quick.models.BaseEntity"  accessors="true" {


    /**
	 * Validate an object or structure according to the constraints rules.
	 * @fields The fields to validate on the target. By default, it validates on all fields
	 * @constraints A structure of constraint rules or the name of the shared constraint rules to use for validation
	 * @locale The i18n locale to use for validation messages
	 * @excludeFields The fields to exclude from the validation
	 * @includeFields The fields to include in the validation
	 *
	 * @return cbvalidation.model.result.IValidationResult
	 * @throws ValidationException error
	 */
	public struct function validateOrFail(
		any constraints = this.getConstraints(),
		string fields = "*",
		string locale = "",
		string excludeFields = "",
		string includeFields = ""
	) {
		var result = _wirebox
			.getInstance( "ValidationManager@cbvalidation" )
			.validateOrFail(
				target = this,
				fields = arguments.fields,
				constraints = arguments.constraints,
				locale = arguments.locale,
				excludeFields = arguments.excludeFields,
				includeFields = arguments.includeFields
			);
		return this;
	}

}