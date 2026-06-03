-- Integridad inter-tabla que la normalización (3FN) y las FKs no pueden expresar:
-- una Interview debe usar un InterviewStep que pertenezca al InterviewFlow de la
-- Position asociada a su Application.
--
--   Interview.applicationId -> Application.positionId -> Position.interviewFlowId  (flujo esperado)
--   Interview.interviewStepId -> InterviewStep.interviewFlowId                      (flujo real)
--
-- Se valida en BEFORE INSERT OR UPDATE de las columnas que intervienen.

CREATE OR REPLACE FUNCTION check_interview_step_flow() RETURNS TRIGGER AS $$
DECLARE
  position_flow_id INTEGER;
  step_flow_id     INTEGER;
BEGIN
  SELECT p."interviewFlowId"
    INTO position_flow_id
    FROM "Application" a
    JOIN "Position" p ON p."id" = a."positionId"
   WHERE a."id" = NEW."applicationId";

  SELECT s."interviewFlowId"
    INTO step_flow_id
    FROM "InterviewStep" s
   WHERE s."id" = NEW."interviewStepId";

  IF position_flow_id IS DISTINCT FROM step_flow_id THEN
    RAISE EXCEPTION
      'Interview.interviewStepId % (flow %) does not belong to the interview flow % of the application''s position',
      NEW."interviewStepId", step_flow_id, position_flow_id
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_interview_step_flow
  BEFORE INSERT OR UPDATE OF "applicationId", "interviewStepId" ON "Interview"
  FOR EACH ROW
  EXECUTE FUNCTION check_interview_step_flow();
